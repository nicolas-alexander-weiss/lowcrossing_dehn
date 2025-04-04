"""
@author: Nicolas
@created: 2023-08-05

Goal: Try to distinguish the pairs from "subgroup_invariant/groups_of_same_volume_alex_knotFloer_coversdeg7_subgrpIdx6.csv"
        by using the new snappy covers function.
"""

import ast
import csv
import snappy
from datetime import datetime

import multiprocessing

from pebble import ProcessPool
import sys

from census_csv_tools import *


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

def add_to_list(csv_file_path, row, columns, delimiter=","):
    """ Appends a row to the file."""

    with open(csv_file_path, "a", newline='') as file:
        writer = csv.DictWriter(file, fieldnames=columns, delimiter=delimiter)
        writer.writerow(row)

def accumulate_computed_invariants(csv_invariants_list, columns, delimiter=","):
    """
        Considers the list of computed invariants and compiles this into an invariant dict.
        The rows are given as:
            knot_name, computed invariant
        for example:
            K15a10035, {"num_covers":{"deg_n":#res}} or {"turaev_viro:{...}}
            --> Better: {"num_covers_deg_n":#cov, "turaev_viro_k":"<inv>"}

        TODO: When merging in the dicts from the csv, should verify that there are no duplications.
    """
    accumulated_invariants = {}
    with open(csv_invariants_list, newline='') as file:
        reader = csv.DictReader(file, delimiter=delimiter, fieldnames=columns, skipinitialspace=True)
        for row in reader:
            # skip first line if it is header
            if row[columns[0]] == columns[0]:
                continue
            # Integrate the row into the invariants dict.

            field_at_idx_1 = ast.literal_eval(row[columns[1]])
            assert(type(field_at_idx_1) == dict)

            if row[columns[0]] not in accumulated_invariants.keys():
                accumulated_invariants[row[columns[0]]] = field_at_idx_1
            else:
                for invariant in field_at_idx_1.keys():
                    accumulated_invariants[row[columns[0]]][invariant] = field_at_idx_1[invariant]

    return accumulated_invariants

def compute_covers(name, csv_inv_path, deg, debug_level=0, lock=None):
    """
    Uses the new snappy to compute the number of covers (upto iso) of
    the dehn-filled knot.
    """

    if debug_level > 0:
        print("[{}] Start computation for deg {} covers of {}(0,1)".format(name, deg, name))
        sys.stdout.flush()

    K = snappy.Manifold(name)
    K.dehn_fill((0,1))
    n = len(K.covers(deg))

    row = {"knot":name, "invariant":{"num_covers_deg_{}".format(deg):n}}

    # acquire the lock
    if lock != None:
        lock.acquire()

    add_to_list(csv_inv_path, row, columns=["knot", "invariant"])

    # release the lock
    if lock != None:
        lock.release()

    if debug_level > 0:
        print("[{}] End: Num deg {} covers of {}(0,1) = {}".format(name, deg, name, n))
        sys.stdout.flush()

def compute_covers_in_parallel(knots, csv_invariants_list, deg, num_workers, debug_level=0, timeout=None):
    """
    Loads the computedinvariants and checks for which knots we still need to compute 
    the invariant for the given degree.
    """

    # 1) Load the already computed invariants:

    already_computed_invariants = accumulate_computed_invariants(csv_invariants_list,columns=["knot", "invariant"]) 

    # 2) Go through the list <knots> and check if already the invariant of the correct degree is computed.
    # Create lock and the pool
    with multiprocessing.Manager() as manager:
        lock = manager.Lock()
        with ProcessPool(max_workers=num_workers) as pool:
            for k in knots:
                if k in ["K15n21809"]:
                    continue
                if (k not in already_computed_invariants.keys() 
                        or "num_covers_deg_{}".format(deg) not in already_computed_invariants[k].keys()):

                    future = pool.schedule(compute_covers, args=(k, csv_invariants_list, deg, debug_level, lock), timeout=timeout)
                    future.add_done_callback(std_callback)


def distinguish_groups_in_parallel(csv_group_path, group_columns, csv_out_path, method="covers"):
    """
    Regarding method: Which invariant to compute.
    """

    # 1) Load the groups, i.e. dict with the group members.
    # Also load the already computed results of the degree 1 higher.
    ### ==> Actually: Might want to keep all the results in the single file. Such that they are posted there as they roll in .
    ### ==> Then I don't have to deal with the stuff
    ### ==> Might want to accumulate the things

    # Have a trigger whether I should do further computation. I.e. might skip

    # 2) Compute for each one. 1 higher
    ## Output to the respective file: let n be the degree, then output
    ## to num_covers_deg_n.csv

    # PERHAPS: maybe we can also add a listener which breaks the computation as soon as a group is successfully separated.

    ## Might also want to send a message every time a computation is done!




    # 3) Based on the available results. Now load all the computed stuff again.
    # But accumulate the computed degrees in a dict.

def get_knots_to_compute(previous_groups_csv,columns):
    results_list = load_knots_from_csv(previous_groups_csv, columns)

    knots = set()

    for row in results_list:
        group = ast.literal_eval(row["group"])
        for k in group:
            knots.add(k)
    
    return knots


def get_knots_to_compute_in_order(previous_groups_csv, columns):
    results_list = load_knots_from_csv(previous_groups_csv, columns)

    knots = []

    for row in results_list:
        group = ast.literal_eval(row["group"])
        for k in group:
            knots.append(k)
    
    return knots



if __name__ == "__main__":

    debug_level = 2
    num_workers = 450
    timeout=None
    deg=8

    total_start_time = datetime.today().now()
    print("---------------------------------------------")
    print("OVERALL STARTING TIME: {}.".format(total_start_time))
    print("---------------------------------------------\n")


    print("Starting the computation for deg {} covers, num_workers = {}".format(deg, num_workers))

    previously_computed_groups_csv = "groups_of_same_volume_alex_knotFloer_coversdeg7_subgrpIdx6.csv"
    computed_invariants_csv = "computed_invariants.csv"
    
    knots = get_knots_to_compute_in_order(previous_groups_csv=previously_computed_groups_csv, columns=["group", "invariant"])

    print("Knots to consider:\n", knots)

    accumulated_invariants = accumulate_computed_invariants(computed_invariants_csv, ["knot", "invariant"])
    print("\nbefore: \n", accumulated_invariants)

    compute_covers_in_parallel(knots, computed_invariants_csv, deg=deg, num_workers=num_workers, debug_level=debug_level, timeout=timeout)

    accumulated_invariants = accumulate_computed_invariants(computed_invariants_csv, ["knot", "invariant"])
    print("\nafterwards: \n", accumulated_invariants)

    total_end_time = datetime.today().now()
    print("---------------------------------------------")
    print("ALL FINISHED AT {}".format(total_end_time))
    print("TOTAL TIME TAKEN: {}.".format(total_end_time - total_start_time))
    print("---------------------------------------------\n")

