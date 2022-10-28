"""
@created: 2022-09-20

@author: Nicolas Alexander Weiss

@goal: Sort the lower crossing knots (5-9) and higher crossing knots (16-19) 
        by their Alexander polynomial.

@software: snappy

@remark: "group" might not the best term to be overloaded here.

"""

import ast

from datetime import datetime
from genericpath import isfile
import multiprocessing
from time import sleep

from pebble import ProcessPool
from concurrent.futures import TimeoutError
from multiprocessing import ProcessError, shared_memory

import numpy as np

import snappy
from census_csv_tools import *

import os, sys

##################################################
### Create the csv files for the groups

def create_low_crossing_groups():
    
    print("\n---------------------------------------------")
    print("Creating groups by alexander poly for the low crossing knots up to 9 crossings.")

    # get the low_crossing_knots with crossings upto :
    low_crossing_knots = []
    for n in (5,6,7,8,9):
        low_crossing_knots += snappy.LinkExteriors(knots_vs_links="knots", crossings=n)
    
    print("There are {} knots of crossing number 5-9".format(len(low_crossing_knots)))

    groups = {}

    # Sort the low_crossing_knots by their alexander polynomial
    # Until we know that str(dict) == str(dict') ==> dict == dict', 
    #  we need to actually compare dictionaries for safety.
    for k in low_crossing_knots:
        name = k.name()
        alexander = k.alexander_polynomial()
        alex_dict = alexander.dict()
        alex_dict_str = str(alex_dict)

        found = False
        key = alex_dict_str
        for k_dict_str in groups.keys():
            if alex_dict == ast.literal_eval(k_dict_str):
                key = k_dict_str
                found = True
                break

        if not found:
            groups[key] = []
        
        groups[key].append({"knot":name, "crossings":len(k.link().crossings)})
    
    print("Number of different Alexander polynomials: {}".format(len(groups.keys())))

    print("Removing the 5_2 knot")

    knot5_2 = snappy.Manifold("5_2")
    dict_str5_2 = str(knot5_2.alexander_polynomial().dict())

    groups.pop(dict_str5_2, None)

    #print(groups)

    print("\nNow creating the group files.")

    distinction_list = []
    for k in groups.keys():
        representative = groups[k][0]["knot"]
        csv_path = "groups/" + representative + ".csv"
        distinction_list.append({"knot":representative, "alexander_polynomial":k})
        print_knots_to_csv(groups[k], columns=["knot", "crossings"], csv_file_path=csv_path)

    print("\nNow creating the distinction file.")
    print_knots_to_csv(distinction_list, columns=["knot", "alexander_polynomial"], csv_file_path="distinction_list.csv")

    print("\nDone for now.")
    print("---------------------------------------------\n")
    sys.stdout.flush()

def get_distinction_list():
    return load_knots_from_csv("distinction_list.csv", columns=["knot", "alexander_polynomial"])

def get_distinction_rows():
    """ Returns almost the same as the above, but keeps the rows in a comma separated fashion.
    # Remark: This is slightly redundant, we could have also implemented this more directly.
    """
    d_list = get_distinction_list()
    return [k["knot"] + "," + k["alexander_polynomial"] for k in d_list]


##################################################
### Sort in the knots from Burton's lists

def add_to_list(csv_file_path, row, columns=["knot", "crossings"], delimiter=","):
    """ Appends an item to the group file.
    """

    # TODO: Might want to work with a write lock given the large amount of processes!

    with open(csv_file_path, "a", newline='') as file:
        writer = csv.DictWriter(file, fieldnames=columns, delimiter=delimiter)
        writer.writerow(row)

def numerical_dt(alpha_dt):
    """ Changes Dowker-Thistlewait notation from alphabetical to numerical
    Input:
        dt_code (string): alphabetical DT notation
    Return:
        (string): numerical DT notation (with "DT: " prepended!)
    """
    alpha = "abcdefghijklmnopqrstuvwxyz"
    Alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    result = []
    for letter in alpha_dt:
        if letter in alpha:
            result.append(2* (alpha.index(letter) + 1))
        elif letter in Alpha:
            result.append(-2 * (Alpha.index(letter) + 1))
        else:
            print(alpha_dt)
    return "DT: " + str([tuple(result)])

def add_burton_knot_to_groups(name, alpha_dt_code, shm_name, shm_count_name, knot_info_count):
    """ Takes a knot from Burtons list.
    
    The distinction list will be passed an object in shared memory.

    Will convert first the DT code and then constructs the snappy knot.

    Looping over the possible groups (until the minimal crossing number is too big),
    a group with same Alexander polynomial is identified (if exists) and the knot inserted.
    
    """

    # load the list from shared memory (still comma-separated)
    dist_rows = shared_memory.ShareableList(name=shm_name)

    # load the count from shared memory  (count[0] = processed knots, count[1] = matched knots)
    shm_count = shared_memory.SharedMemory(name=shm_count_name)
    count = np.ndarray((2,), dtype=np.int64, buffer=shm_count.buf)

    count[0] += 1

    if count[0] % knot_info_count == 0:
        print("Currently on knot {}".format(count[0]))
    sys.stdout.flush()
    
    # create the link and compute the alexander polynomial
    link = snappy.Link(numerical_dt(alpha_dt_code))
    alex_poly = link.alexander_polynomial()
    alex_poly_dict = alex_poly.dict()
    crossings = len(link.crossings)



    for knot_row in dist_rows:
        comma = knot_row.find(",")
        k_name = knot_row[:comma]
        dict_str = knot_row[comma+1:]
        k_poly_dict = ast.literal_eval(dict_str)

        k_crossings = int(k_name[0]) # given by the first letter.

        # since the list in shared memory is sorted, we may already quit, if the crossing number
        # is too large!
        if k_crossings > 25 - crossings:
            break

        if k_crossings <= 25 - crossings and k_poly_dict == alex_poly_dict:
            path = "groups/" +  k_name + ".csv"
            # print("Adding {} with poly {} to {} with poly {}".format(name, alex_poly_dict, k_name, k_poly_dict))
            print("Adding {} with poly {} to {}".format(name, alex_poly_dict, k_name))
            add_to_list(path, {"knot":name, "crossings":len(link.crossings)})
            
            count[1] += 1
            break

    # close the shared memory
    dist_rows.shm.close()
    shm_count.close()
    
    # flush
    sys.stdout.flush()

def process_burton_list(csv_file_path, info_count, knot_info_count, max_workers, info_name, continue_at=None, sleep_time=0.001):
    """ Given the length of the files, the knot lists will not be turned into a 
    list of dicts (would be too much overhead), but will be processed with the standard
    csv utilities.

    Will print a note after <info_count> many knots have been looped over.
    Will print a note after <knot_info_count> many knots have been actually processed.

    ---- Arguments -----

    continue_at : either string -> knot_name, or int -> row_count


    """
    start_time = datetime.today().now()
    
    print("\nStarting the processing of {} at {}.\n".format(csv_file_path, start_time))

    # load the comma-separated distinction list into shared memory.
    distinction_rows = sorted(get_distinction_rows())
    shm_list = shared_memory.ShareableList(distinction_rows)
    shm_name = shm_list.shm.name

    # A general count of processed knots in shared memory:  
    # This is more messy than necessary!
    # TODO: Clean up!!!
    a = np.array([0,0])
    shm_count = shared_memory.SharedMemory(create=True, size=a.nbytes)
    shm_count_name = shm_count.name
    count = np.ndarray(a.shape, dtype=a.dtype, buffer=shm_count.buf)
    count[:] = a[:]

    continuation_point_found = True # Default case, if nothing should be skipped!
    if continue_at != None:
        continuation_point_found = False

    # callback function for the multiprocessing.
    def insertion_done(future): # call back
        try:
            result = future.result() # blocks until done.
        except TimeoutError as error:
            print("Ended computation after {} seconds".format(error.args[1]))
        except Exception as error:
            print("Function raised {}".format(error))
            print(error.traceback)  # traceback of the function


    # Remark: All files share these three columns, but there might be additional ones.
    columns = ["name", "knot_sig", "dt_code"]
    delimiter = ","

    # iterate over the knots in the Burton file and create a process for each.
    with open(csv_file_path, newline='') as file:
        reader = csv.DictReader(file, delimiter=delimiter, fieldnames=columns, skipinitialspace=True)

        # using the "with (..):" statement, the pool will be closed automatically afterward.
        with ProcessPool(max_workers=max_workers) as pool:

            for idx, row in enumerate(reader):
                # skip first line if it is header
                if row[columns[0]] == columns[0]:
                    continue

                name = row["name"]
                dt_code = row["dt_code"]

                # IMPLEMENT CONTINUATION FUNCTION:
                
                if not continuation_point_found:
                    if idx % 100000 == 0:
                        print("Skipping lines until continuation: Current idx = {}.".format(idx))
                    if type(continue_at) == int:
                        # Hence it is a row count.
                        if idx < continue_at:
                            count[0] += 1 # processed knots.
                            continue
                        else:
                            continuation_point_found = True
                            print("Now continueing at idx {} with knot {}.".format(idx, name))
                            sys.stdout.flush()

                    elif type(continue_at) == str:
                        # Hence it is a knot name.
                        if name != continue_at:
                            count[0] += 1
                            continue
                        else:
                            continuation_point_found = True
                            print("Now continueing at idx {} with knot {}.".format(idx, name))
                            sys.stdout.flush()

                """ if csv_file_path == "../burton_knots/19a-hyp.csv" and idx < 39850000:
                    if idx % 50000 == 0:
                        print("passed by idx {}".format(idx))
                        sys.stdout.flush()
                    continue


                if csv_file_path == "../burton_knots/19a-hyp.csv" and idx == 39850000:
                    print("Now continueing at 39850000th row again.")
                    sys.stdout.flush() """

                # print(row)
                
                if idx % info_count == 0 and info_count != -1:
                    print("[{}]: Read-in {} lines.".format(info_name, idx))
                    sys.stdout.flush()

                

                # add the process.
                future = pool.schedule(add_burton_knot_to_groups, args=(name, dt_code, shm_name, shm_count_name, knot_info_count))
                future.add_done_callback(insertion_done)

                print("Added_Info")

                # sleep, to prevent memory overload:
                sleep(sleep_time)

    # report:
    end_time = datetime.today().now()
    print("\nConclude the sorting-in of the knots in {}.".format(csv_file_path))
    print("For {} out of {} knots there is a matching lowcrossing knot.".format(count[1], line_count(csv_file_path)-1))
    print("Finished after: {}s\n".format(end_time - start_time))
    sys.stdout.flush()

    # close the shared memory and release memory.
    shm_list.shm.close()
    shm_list.shm.unlink()

    shm_count.close()
    shm_count.unlink()

#################################
# Preprocessing
#

def line_count(path):
    """ Returns the number of lines in the file.
    """
    with open(path, "r") as file:
        count = sum([1 for _ in file])
    return count

def split_file(path, num_chunks):
    """ The larger files will be split into <num_chunks> lists, so that they can be processed
    in parallel.

    ### Remark: might be better to do this manually, with something like:
    split ../burton_knots/16a-hyp.csv ../burton_knots/16a-hyp.csv --lines=25000 --numeric-suffixes=1

    ### Remark: Even if we cut up the files. We can still later on concatenate them again with cat.
    """
    assert(num_chunks <= 16)
    # Remark: In "--number=l/N", N stands for the number of chunks and l/ indicates that no lines shall be broken.
    os.system("split {} {} --number=l/{} --numeric-suffixes=1".format(path, path, num_chunks))

def delete_splits(path, num_chunks):
    assert(num_chunks <= 16)
    for i in range(1, num_chunks + 1):
        # print("rm {}".format(path) + "{:02d}".format(i))
        os.system("rm {}".format(path) + "{:02d}".format(i))


#################################
# Actual Execution
#

def process_the_burton_lists_in_parallel(num_chunks, max_workers, info_count, knot_info_count):
    """ Processes the Burton's list of knots.
    For the large knot lists, we will split them up 
    into <num_chunks> chunks and process them in parallel.
    """
    # callback function for catching exceptions.
    def processing_done(future): # call back
        try:
            result = future.result() # blocks until done.
        except Exception as error:
            print("Function raised {}".format(error))
            print(error.traceback)  # traceback of the function

    for filename in knot_lists:
        burton_file = "../burton_knots/" + filename

        # if filename in large_lists:
        #     # split the large file
        #     split_file(burton_file, num_chunks=num_chunks)

        #     # create a pool where each process considers one of the chunks!
        #     with ProcessPool(max_workers=num_chunks) as pool:
        #         for chunk_idx in range(1, num_chunks + 1):
        #             path = burton_file + "{:02d}".format(chunk_idx)
        #             future = pool.schedule(process_burton_list, args=(path, info_count, knot_info_count, max_workers // num_chunks, filename + "{:02d}".format(chunk_idx)))
        #             future.add_done_callback(processing_done)

        #     # delete the splits
        #     delete_splits(burton_file, num_chunks=num_chunks)
        # else:
        process_burton_list(burton_file, info_count, knot_info_count, max_workers=max_workers, info_name=filename, continue_at = None, sleeptime=0.0288) # sleep time so that 1mio knots per 30min.


######################################
"""
New Approach:

- for each file create a file for keeping track if being processed.
- This approach will be more memory intense but likely worth it

1. Go through the list of knot lists:
    - For each file create (if not exist already) two lists:
        <knot>.no_group.csv  (only store the name)
        <knot>.with_group.csv (store name and name of group and alex poly)

2. Sorting in the knots:
    // Check whether there is an "all processed remark" (-> 3.) and then skip.
    - Load in the lists of processed knots as sets
    - For each knot, check (O(1)-time) whether processed
    - If not processed, then add to the pool (and wait some time to limit the number of open processes)

3. Verify that all knots have been processed.
    -> Make remark if all processed (as file)

4. Sort in the knots from the processed list into the actual groups.

Remark:
- It might make sense for the big files, to only run them individually (or in groups)

"""

STD_DELIMITER = ","
STD_BURTON_COLUMNS = ["name", "knot_sig", "dt_code"]

NO_GROUP = ".no_group.csv"
NO_GROUP_COLUMNS = ["name"]
WITH_GROUP = ".with_group.csv"
WITH_GROUP_COLUMNS = ["name", "crossings", "alexander_polynomial", "matched_name"]

BURTON_KNOTS_DIR = "../burton_knots/"
PROCESSED_DIR = "processed/"

MAX_WORKERS = 16
TIME_OUT_PER_KNOT = float(0.0015)

NUM_PROCESSED_INFO = 50000
NUM_READ_INFO = 100000


def create_processed_knots_files(knot_lists):
    """
    For each knot creates, if the files do not exist yet (else writes a message),
    csv files:
    --> <knot>.no_group.csv  (only to store the name)
    --> <knot>.with_group.csv (to store name and name of group and alex poly)
    """

    print("---------------------------------------------")
    print("Create book-keeping files of processed knots.")

    if not os.path.isdir(PROCESSED_DIR):
        os.mkdir(PROCESSED_DIR)

    for list_name in knot_lists:
        processed_no_group = PROCESSED_DIR + list_name + NO_GROUP
        processed_with_group = PROCESSED_DIR + list_name + WITH_GROUP

        if os.path.isfile(processed_no_group):
            print("The file {} already exists!".format(processed_no_group))
        else:
            # create the file
            print_knots_to_csv(knots=[], columns=NO_GROUP_COLUMNS, csv_file_path=processed_no_group) 

        if os.path.isfile(processed_with_group):
            print("The file {} already exists!".format(processed_with_group))
        else:
            # create the file
            print_knots_to_csv(knots=[], columns=WITH_GROUP_COLUMNS, csv_file_path=processed_with_group) 

    print("---------------------------------------------")


def get_processed_sets(knot_list):
    """
        Considers the two lists of processed knots and loads their first column as sets.
        
        Returns: processed_no_group, processed_with_group
    """
    processed_no_group_path = PROCESSED_DIR + knot_list + NO_GROUP
    processed_with_group_path = PROCESSED_DIR + knot_list + WITH_GROUP

    assert(os.path.isfile(processed_no_group_path))
    assert(os.path.isfile(processed_with_group_path))

    processed_no_group = load_first_column_as_set(
        processed_no_group_path,
        columns=NO_GROUP_COLUMNS,
        delimiter=STD_DELIMITER
    )
    processed_with_group = load_first_column_as_set(
        processed_with_group_path,
        columns=WITH_GROUP_COLUMNS,
        delimiter=STD_DELIMITER
    )
    
    return processed_no_group, processed_with_group


def process_knot(knot_list, knot_name, alpha_dt_code, shm_list_name, idx, lock):

    if idx % NUM_PROCESSED_INFO == 0:
        print("[{}]: Now processing knot {} with idx {}".format(knot_list, knot_name, idx))
        sys.stdout.flush()

    # Load shared memory: Count and distinction list as rows
    dist_rows = shared_memory.ShareableList(name=shm_list_name)

    #
    ###
    # create the link and compute the alexander polynomial
    link = snappy.Link(numerical_dt(alpha_dt_code))
    alex_poly = link.alexander_polynomial()
    alex_poly_dict = alex_poly.dict()
    crossings = len(link.crossings)

    found_match = False # to keep track if match was found.

    for knot_row in dist_rows:
        comma = knot_row.find(",")
        k_name = knot_row[:comma]
        dict_str = knot_row[comma+1:]
        k_poly_dict = ast.literal_eval(dict_str)

        k_crossings = int(k_name[0]) # given by the first letter. (upto 9 crossings)

        # since the list in shared memory is sorted, we may already quit, if the crossing number
        # is too large!
        if k_crossings > 25 - crossings:
            break

        if k_crossings <= 25 - crossings and k_poly_dict == alex_poly_dict:
            print("[{}]: Found match for {} with knot:{}, poly: {}.".format(knot_list, knot_name, k_name, alex_poly_dict))
            sys.stdout.flush()

            processed_with_group_path = PROCESSED_DIR + knot_list + WITH_GROUP

            lock.acquire()
            add_to_list(processed_with_group_path, columns=WITH_GROUP_COLUMNS, row={"name":knot_name, "crossings":len(link.crossings), "alexander_polynomial":alex_poly_dict, "matched_name":k_name})
            lock.release()

            found_match = True
            break
    if not found_match:
        processed_no_group_path = PROCESSED_DIR + knot_list + NO_GROUP

        lock.acquire() # make sure no other process writes the file
        add_to_list(processed_no_group_path, columns=NO_GROUP_COLUMNS, row={"name":knot_name})
        lock.release()
    ###
    #

    # detach memory
    dist_rows.shm.close()

    pass


def process_knot_list(knot_list, already_processed_no_group, already_processed_with_group):
    """
        Iterates through the list of knots. If knot was already processed before, skip.
    """
    # Flush what has been printed so far:
    sys.stdout.flush()
    ####################################

    knot_list_path = BURTON_KNOTS_DIR + knot_list

    columns = STD_BURTON_COLUMNS
    delimiter = STD_DELIMITER

    # load the comma-separated distinction list into shared memory.
    distinction_rows = sorted(get_distinction_rows())
    shm_list = shared_memory.ShareableList(distinction_rows)
    shm_list_name = shm_list.shm.name

    #####################################

    # multiprocessing lock for avoiding IO problems
    lock = multiprocessing.Lock()

    # callback function for the multiprocessing.
    def insertion_done(future): # call back
        try:
            result = future.result() # blocks until done.
        except Exception as error:
            print("Function raised {}".format(error))
            print(error.traceback)  # traceback of the function

    #######################################

    start_time = datetime.today().now()
    print("[{}]: Starting the processing at {}".format(knot_list, start_time))

    with open(knot_list_path, newline='') as file:
        reader = csv.DictReader(file, delimiter=delimiter, fieldnames=columns, skipinitialspace=True)
        
        with ProcessPool(max_workers=MAX_WORKERS) as pool:
            for idx, row in enumerate(reader):
                # skip first line if it is header
                if row[columns[0]] == columns[0]:
                    continue

                # Provide an info, each time threshold is reached.
                if idx % NUM_READ_INFO == 0:
                    print("[{}] Read {} lines.".format(knot_list, idx))
                    sys.stdout.flush()

                # Get details
                name = row["name"]
                alpha_dt_code = row["dt_code"]

                # skip if has been processed already
                if name in already_processed_no_group or name in already_processed_with_group:
                    continue
                
                # add the process:
                future = pool.schedule(process_knot, args=(knot_list, name, alpha_dt_code, shm_list_name, idx, lock))
                future.add_done_callback(insertion_done)

                # sleep time, should not per se sleep, but only sleep if too many open tasks.
                # [TODO]: Implement this if things fail again. 
                sleep(TIME_OUT_PER_KNOT)

    # Print information:
    time_taken = datetime.today().now() - start_time

    # get number of knots:
    num_processed_no_group = line_count(PROCESSED_DIR + knot_list + NO_GROUP ) - 1
    num_processed_with_group = line_count(PROCESSED_DIR + knot_list + WITH_GROUP) - 1
    total_processed = num_processed_no_group + num_processed_with_group

    num_already_no_group = len(already_processed_no_group)
    num_already_with_group = len(already_processed_with_group)
    total_already_processed = num_already_no_group + num_already_with_group

    num_new_processed = total_processed - total_already_processed
    num_new_added = num_processed_with_group - num_already_with_group
    

    print("[{}]: Done with processing the list.".format(knot_list))
    print("[{}]: Time take: {}".format(knot_list, time_taken))
    print("[{}]: Total knots processed {} / Total matched {}".format(knot_list, total_processed, num_processed_with_group))
    print("[{}]: New processed {}/ new added {}".format(knot_list, num_new_processed, num_new_added))
    # Close & unlink the shared memory:
    shm_list.shm.close()
    shm_list.shm.unlink()

def verify_processing(knot_list):
    pass

def main(knot_lists):
    """ Main routine.

    Executes for the knot lists specified in <knot_lists>
    """

    # Creating the low_crossing groups (5-9 crossings) and makes a "distinction list"
    # --> /groups/5_1.csv           (etc.)
    # --> ./distinction_list.csv
    create_low_crossing_groups()
    
    # Create if not already exist the files for tracking processed knots
    create_processed_knots_files(knot_lists)

    # process the list
    for knot_list in knot_lists:
        print("\n---------------------------------------------")
        print("---------------------------------------------")
        print("Starting the processing of {}.".format(knot_list))
        print("---------------------------------------------\n")
        
        # load the processed knots as sets
        processed_no_group, processed_with_group = get_processed_sets(knot_list)

        print("Num already processed knots without group: {}".format(len(processed_no_group)))
        print("Num already processed knots with group: {}".format(len(processed_with_group)))

        # process the list
        process_knot_list(knot_list, processed_no_group, processed_with_group)




        print("\n---------------------------------------------")
        print("Done with the processing of {}.".format(knot_list))
        print("---------------------------------------------")
        print("---------------------------------------------\n")

        sys.stdout.flush()

    # verify the processing.
    print("[NOT IMPLEMENTED] Now verifying that all knots have been processed.")

    # Sorting the matched knots into the groups.
    print("[NOT IMPLEMENTED] Now sorting the matched knots into the group lists.")
    
    sys.stdout.flush()



#################################
# The knot lists to be considered
#

knot_lists = [
    "16n-satellite.csv",
    "16n-torus.csv",
    "16a-hyp.csv",
    "16n-hyp.csv",

    "17a-torus.csv",
    "17n-satellite.csv",
    "17a-hyp.csv",
    "17n-hyp.csv",

    "18n-satellite.csv",
    "18a-hyp.csv",
    "18n-hyp.csv",

    "19n-satellite.csv",
    "19a-torus.csv",

    "19a-hyp.csv",
    "19n-hyp.csv"
]

# No need to process the lists in parallel!
large_lists = []

large_lists_old = [
    "16a-hyp.csv",
    "16n-hyp.csv",

    "17a-hyp.csv",
    "17n-hyp.csv",

    "18a-hyp.csv",
    "18n-hyp.csv",

    "19a-hyp.csv",
    "19n-hyp.csv"
]

# REMARK: Should do preprocessing, by splitting the large lists into 16 distinct ones. 
# That way one can process the lists quicker as well.

if __name__ == "__main__":
    
    main(knot_lists)
    
    # create_low_crossing_groups()

    # filename = "19n-hyp.csv"
    # burton_file = "../burton_knots/" + filename

    # process_burton_list(burton_file, info_count=-1, knot_info_count=50000, max_workers=16, info_name=filename, continue_at = "19nh_001633088")
