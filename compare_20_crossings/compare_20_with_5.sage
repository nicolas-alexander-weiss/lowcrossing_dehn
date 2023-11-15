"""
Goal: Compare the 20 crossing prime knots with the 5 crossing knot (5_2?) in regina.

TODO: 
    1. Open a list of the files
    2. Have 32 worker processes, where in each the filling is built and then alexander poly computed.
    3. If an Alexander poly matches the 5_2(0,1) Alexander poly then save. (i.e. into 'filename_matches')


"""

import multiprocessing

from pebble import ProcessPool
import csv, sys, time 


import snappy

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


def add_to_list(csv_file_path, row, columns, delimiter=","):
    """ Appends a row to the file."""

    with open(csv_file_path, "a", newline='') as file:
        writer = csv.DictWriter(file, fieldnames=columns, delimiter=delimiter)
        writer.writerow(row)

def compare(knot_code, filename, target_filename, id, info_interval, lock=None):
    """
    Builds the knot specified by the alphabetical DT code, e.g.

        tatbdegahjckmfnpirlsotq

    and then compares its Alexander polynomial with
    with the Alexander polynomial of 5_1 which is t^4 - t^3 + t^2 - t + 1

    """
    R.<t> = QQ['t'] 

    target_poly = t^4 - t^3 + t^2 - t + 1

    D = snappy.Link("DT: {}".format(knot_code))
    alex_poly = D.alexander_polynomial()

    if (alex_poly == target_poly):

        # acquire the lock
        if lock != None:
            lock.acquire()
        
        add_to_list(target_filename, {"knot_code":knot_code}, columns=["knot_code"])

        # release the lock
        if lock != None:
            lock.release()

    if id % info_interval == 0:
        print("[{}] Processed knot {} with id {}".format(filename, knot_code, id))
        sys.stdout.flush()



def compare_file(filename, target_filename, info_interval, lock, skip_n_knots=0):
    """
        Goes through the knots specified in the file. Stores matches to the target_file.

        If skip_n_knots is specified, it skips the first n knots.
    """

    R.<t> = QQ['t'] 
    target_poly = t^4 - t^3 + t^2 - t + 1

    count = 0

    print("[{}] Starting. Start count specified as: {}".format(filename, skip_n_knots))
    sys.stdout.flush()

    with open(filename) as knot_file:
        for line in knot_file:
            knot_code = line.rstrip()

            if (count < skip_n_knots):
                # Skip the first n knots.
                if count % (10*1000*1000) == 0:
                    print("[{}] Skipping initial knots; currently {} with count {}".format(filename, knot_code, count))
                    sys.stdout.flush()

                count += 1
                continue

            if (count == skip_n_knots):
                print("[{}] Starting computation with knot {} at count {}".format(filename, knot_code, count))
                sys.stdout.flush()

            if count % info_interval == 0:
                print("[{}] Processing knot {} with count {}".format(filename, knot_code, count))
                sys.stdout.flush()
            
            D = snappy.Link("DT: {}".format(knot_code))
            alex_poly = D.alexander_polynomial()
            
            if (alex_poly == target_poly):

                # acquire the lock
                if lock != None:
                    lock.acquire()
                
                add_to_list(target_filename, {"knot_code":knot_code}, columns=["knot_code"])

                # release the lock
                if lock != None:
                    lock.release()
            
            count += 1

    print("[{}] Done processing.".format(filename))
    sys.stdout.flush()

## RMK: ASSUMES THAT THE RESPECTIVE FILES HAVE BEEN split into "filename_x{}" ranging from 0 to 31.

if __name__ == "__main__":
    num_workers = 32

    # Rmk. updated the file list since the other ones have been already processed.
    filenames = ["nonalt_hyp_20"] 
    # ["nonhyp_20", "nonhyp_3_20_all", "alt_20", "nonalt_hyp_20"] # The files have to be downloaded separetly from MT's website.

    start_counts = {
        "nonalt_hyp_20" : 28000000
    }

    info_interval = 10000


    for filename in filenames:

        print("[{}] Starting processing.".format(filename))
        sys.stdout.flush()

        target_filename = filename + "_matches.csv"

        with multiprocessing.Manager() as manager:
            lock = manager.Lock()
            with ProcessPool(max_workers=num_workers) as pool:
                for i in range(0,32):
                    future = pool.schedule(compare_file, args=("knot_data/" + filename + "_x{:02d}".format(i), target_filename, info_interval, lock, start_counts[filename]))
                    future.add_done_callback(std_callback)

        print("[{}] Done.".format(filename))
        sys.stdout.flush()
    
    print("[{}] Done with all.".format(filename))
    sys.stdout.flush()
    
            

