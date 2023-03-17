"""
@author: Nicolas
@created: 2023-03-14

Goal: Given an input list of lists containing the knots to be distinguished

"""
import ast
import csv
from collections import Counter
from datetime import datetime
import multiprocessing

import os
from pebble import ProcessPool
import sys

import census_csv_tools

import snappy

########
###### Call back functions:
# callback function for the multiprocessing.
def std_callback(future): # call back
    try:
        result = future.result() # blocks until done.
    except TimeoutError as error:
        print("Ended computation after {} seconds".format(error.args[1]))
    except Exception as error:
        print("Function raised {}".format(error))
        print(error.traceback)  # traceback of the function

########

def get_gap_group_presentation(snappy_group, split_str="_"):
    """
        A group in snappy is described by 
            snappy_group.generators() , i.e. ['a', 'b']
            and
            snappy_group.relators() , i.e. ["rel1", "rel2",...]

        For our gap program, we want to concatenate the relations into a single string of the form
        "1=rel1=rel2=...".
    """
    rel_str = "1"
    for rel in snappy_group.relators():
        rel_str += "=" + rel

    assert(len(snappy_group.generators()) <= 26)
    gen_str = ""
    for g in snappy_group.generators():
        gen_str += g + split_str

    # Remove trailing '_'
    gen_str = gen_str[:-1]
    

    return {"generator_str": gen_str, "relator_str":rel_str}

#
# IMPORTANT: When gap reads a string, it should be in double quotes! (but reading from CSV should be fine!)
#
# DECISION: Writing the list of generators as a string. But for this have to assert that there are at
#           most 26 generators, else we run into trouble.

def write_dehnfilled_group_description_to_csv(outpath, snappy_name):
    mfld = snappy.Manifold(snappy_name)
    mfld.dehn_fill((0,1))

    f_group_description = get_gap_group_presentation(mfld.fundamental_group())

    row = {"name":snappy_name, 
           "generator_str": f_group_description["generator_str"], 
           "relator_str":f_group_description["relator_str"] }
    
    pass # TODO: Fill this out perhaps if want to do a bit of batch-processing


def compute_invariant_in_gap(snappy_group, max_index, split_str="_"):
    gap_presentation = get_gap_group_presentation(snappy_group)

    command = "./get_inv.sh {} {} {} {}".format(gap_presentation["generator_str"], gap_presentation["relator_str"], split_str, max_index)
    print("The command: \n", command, "\n")
    sys.stdout.flush()
    stream = os.popen(command)
    output = stream.read().replace("\n", "").replace(" ", "")
    
    #
    # Remark: We also want to make sure that all the inner lists are considered tuples in python, so that order is
    #           immutable and we can hash.
    #

    list_invariant = ast.literal_eval(output)
    multiset_invariant = Counter([tuple(tuple(x) if type(x)==list else x for x in ll) for ll in list_invariant])
    
    # REMARK: We use a multiset (counter), because sometimes there are two distinct conjugate classes of
    #           subgroups of the same index with same information.

    # Counter objects are still hashable, so we can nicely compare two multisets.

    return multiset_invariant

def add_to_list(csv_file_path, row, columns, delimiter=","):
    """ Appends a row to the file."""

    with open(csv_file_path, "a", newline='') as file:
        writer = csv.DictWriter(file, fieldnames=columns, delimiter=delimiter)
        writer.writerow(row)

def compute_invariant_to_csv(snappy_name, max_index, csv_out_path, lock):
    mfld = snappy.Manifold(snappy_name)
    mfld.dehn_fill((0,1))

    invariant = compute_invariant_in_gap(mfld.fundamental_group(), max_index)
    row = {"knot": snappy_name, "invariant":dict(invariant)}

    # acquire the lock
    if lock != None:
        lock.acquire()

    add_to_list(csv_out_path, row, columns=["knot", "invariant"])

    # release the lock
    if lock != None:
        lock.release()


def compute_invariants_in_parallel(groups_csv_path, columns, csv_out_path, num_workers):
    """Computes the subgroup invariant upto the given index for all the knots appearing in the groups_csv file.

    Arguments:
        - groups_csv_path: CSV file with headers given by <columns>, at least containing "rep" and "group".
        - out_csv_path: Will output with columns ["knot", "invariant"] to the output file. 
    """
    total_start_time = datetime.today().now()
    print("---------------------------------------------")
    print("OVERALL STARTING TIME: {}.".format(total_start_time))
    print("---------------------------------------------\n")

    # Load the groups

    assert("rep" in columns and "group" in columns)

    groups_csv = census_csv_tools.load_knots_from_csv(groups_csv_path, columns)

    # Create lock and the pool
    with multiprocessing.Manager() as manager:
        lock = manager.Lock()
        with ProcessPool(max_workers=num_workers) as pool:
            for row in groups_csv:
                group = ast.literal_eval(row["group"])

                for knot in group:
                    future = pool.schedule(compute_invariant_to_csv, args=(knot, max_index, csv_out_path, lock))
                    future.add_done_callback(std_callback)

    total_end_time = datetime.today().now()
    print("---------------------------------------------")
    print("ALL FINISHED AT {}".format(total_end_time))
    print("TOTAL TIME TAKEN: {}.".format(total_end_time - total_start_time))
    print("---------------------------------------------\n")

    sys.stdout.flush()

def distinguish_groups(csv_group_path, group_columns, invariants_path, invariants_columns):
    invariants = census_csv_tools.load_knots_from_csv(invariants_path, columns=invariants_columns)
    invariant_dict = {row["knot"]:ast.literal_eval(row["invariant"]) for row in invariants}
    
    # print(invariant_dict)
    print("Num keys in the invariant dict: {}\n".format(len(invariant_dict.keys())))

    group_list = census_csv_tools.load_knots_from_csv(csv_group_path, columns=group_columns)
    
    #


    print("\n----\n")
    print("Remark: There are some duplicates in our list of knots!\n")
    # Find some duplicates:
    keys = []
    duplicates = set({})
    for row in invariants:
        if row["knot"] not in keys:
            keys += [row["knot"]]
        else:
            duplicates.add(row["knot"])
    
    # print("Duplicates: {}".format(duplicates))
    print("There are {} distinct knots appearing more than once.".format(len(duplicates)))

    # print("\n........................\n")
    # print("We will now merge the list (by transitivity...)!")


    new_distinction_list = []

    count = 0
    num_non_singleton_groups = 0
    for row in group_list:
        group = ast.literal_eval(row["group"])
        
        distinction_list = []
        for knot in group:
            found_match = False
            for subgroup in distinction_list:
                if subgroup["invariant"] == invariant_dict[knot]:
                    subgroup["members"] += [knot]
                    found_match = True
                    break
            if not found_match:
                distinction_list += [{"invariant":invariant_dict[knot], "members":[knot]}]
        
        # check if new groups created
        if len(distinction_list) != 1:
            count += 1
            # print("New groups were created!!")
        
        for grp in distinction_list:
            if len(grp["members"]) > 1:
                num_non_singleton_groups += 1
        
        # insert the new group into the distinction lists
        new_distinction_list += distinction_list

    # print("The new distinction list: \n", new_distinction_list)

    print("The new distinction list contains {} non-trivial groups.\n".format(num_non_singleton_groups))
    print("The invariant helped to distinguish the elements of a group in {} cases.\n".format(count))


            

#
# Note: deg 4 subgroups were computed for all ~9000 knots in ~1h50min.
#
#



if __name__ == "__main__":
    recompute_invariant = False

    max_index = 5
    in_groups_csv = "../enumerate_covers/groups_of_same_volume_alex_knotFloer_coversdeg7.csv"
    group_columns = ["rep","covers","group"]
    
    invariants_path = "subgrpinv_upto_" +  str(max_index) + ".csv"
    inv_columns = ["knot","invariant"]

    if recompute_invariant or not os.path.isfile(invariants_path):
        compute_invariants_in_parallel(in_groups_csv, columns=group_columns, csv_out_path=invariants_path, num_workers=16)

    print("Now distinguishing the groups by the given invariants")
    distinguish_groups(in_groups_csv, group_columns, invariants_path, inv_columns)
