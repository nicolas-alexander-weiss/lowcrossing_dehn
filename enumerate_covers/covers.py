"""
@author: Nicolas Weiss
@created: 2022-12-11

@goal: Use Burton's implementation within Regina to compute (in parallel) the number of covers
for the not yet distinguished 0-fillings.

@software: Regina 7.2
"""

import ast
import csv
from datetime import datetime
import multiprocessing
from pebble import ProcessPool
import pickle
import sys

import census_csv_tools

import snappy



probably_equal = [
    [['o9_33067',
    "JSJ([('SFSpace', 'SFS [A: (2,1)]'), ('SFSpace', 'SFS [A: (3,2)]')])"],
    ['o9_34323',
    "JSJ([('SFSpace', 'SFS [A: (2,3)]'), ('SFSpace', 'SFS [A: (3,5)]')])"]],
    [['o9_27542', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm015')])"],
    ['o9_33568', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm015')])"]],
    [['o9_31828', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm032')])"],
    ['o9_37768', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm032')])"]]
]

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


def compute_covers_zero_surgery(snappy_name, deg_range):
    """
    TODO: Verify if that is the correct filling!!!

    This constructs the snappy manifold, copies it into regina, where it specifically needs 
    to be considered as a SnapPea Triangulation. There one then can do fillings and have them solidified 
    in the triangulation.

    If one first Dehn-fills a knot in snappy and then copies it into Regina, the filling information 
    will be lost!!!
    
    """
    M = snappy.Manifold(snappy_name)
    # M_reg = SnapPeaTriangulation(Triangulation3(M))
    # REMARK: THE ABOVE IS NOT LOSSLESS. Information about longitude and meridian is not correctly transferred.

    M.dehn_fill((0,1))

    g_snappy = M.fundamental_group()

    # in regina:
    g_regina = GroupPresentation(len(g_snappy.generators()), g_snappy.relators())
    num_covers = [len(g_regina.enumerateCovers(i)) for i in range(deg_range[0], deg_range[1]+1)]
    
    return num_covers



OUTPUT_COLUMNS = ["representative","covers","members"]

def add_to_list(csv_file_path, row, columns, delimiter=","):
    """ Appends a row to the file."""

    with open(csv_file_path, "a", newline='') as file:
        writer = csv.DictWriter(file, fieldnames=columns, delimiter=delimiter)
        writer.writerow(row)


def distinguish_knotgroup_by_covers(group, deg_range, csv_output=None, lock=None):
    # compute covers
    covers = {knot:compute_covers_zero_surgery(knot, deg_range) for knot in group}

    # now make new groups:
    new_groups = {}
    for knot in covers.keys():
        key = str(covers[knot])
        if key in new_groups.keys():
            new_groups[key].append(knot)
        else:
            new_groups[key] = [knot]
    

    if csv_output == None:
        return new_groups

    # acquire lock if passed as argument
    if lock != None:
        lock.acquire()

    # print the groups

    columns = ["representative", "covers", "members"]

    for key in new_groups.keys():
        row = {"representative":new_groups[key][0], "covers":key, "members":new_groups[key]}
        add_to_list(csv_file_path=csv_output, row=row, columns=columns)

    if lock != None:
        lock.release()


def distinguish_groups_by_covers_parallel(groups, deg_range, csv_out_path, num_workers, limit_num_groups=-1):

    """
    Computes the covers for the specified range of deg and 
    tries to distinguish the groups.
    """

    total_start_time = datetime.today().now()
    print("---------------------------------------------")
    print("OVERALL STARTING TIME: {}.".format(total_start_time))
    print("---------------------------------------------\n")

    # Load groups and initial analysis
    #
    if len(groups) < limit_num_groups:
        limit_num_groups = len(groups)
    
    if limit_num_groups > 0:
        groups = groups[:limit_num_groups]

    # print("First 10 groups from the list:\n{}".format(groups[:10]))
    print("Group Size max: {}".format(max([len(group) for group in groups])))
    print("Number of groups: {}\n".format(len(groups)))


    # Create lock and the pool
    with multiprocessing.Manager() as manager:
        lock = manager.Lock()
        with ProcessPool(max_workers=num_workers) as pool:
            for group in groups:
                future = pool.schedule(distinguish_knotgroup_by_covers, args=(group, deg_range, csv_out_path, lock))
                future.add_done_callback(std_callback)

    total_end_time = datetime.today().now()
    print("---------------------------------------------")
    print("ALL FINISHED AT {}".format(total_end_time))
    print("TOTAL TIME TAKEN: {}.".format(total_end_time - total_start_time))
    print("---------------------------------------------\n")

    sys.stdout.flush()


def load_groups_from_csv(csv_file):
    rows = census_csv_tools.load_knots_from_csv(csv_file, OUTPUT_COLUMNS)
    return [ast.literal_eval(row["members"]) for row in rows]

def get_nontrivial_groups(groups):
    new_groups = []

    for group in groups:
        if len(group) != 1:
            new_groups.append(group)
    
    return new_groups




if __name__ == "__main__":
    groups_pickle_path = "../Equal 0-surgeries/groups_of_same_volume_alex_knotFloer.pickle"

    num_workers = 16


    print("Starting with the computation of the covers up to deg 6.\n")

    deg_range = (2,6)
    csv_out_path = "results2-6.csv"

    with open(groups_pickle_path, "rb") as file:
        groups = pickle.load(file)


    # CLEAN UP THE LIST, there are doubled groups. 
    #   (here assuming that if they are doubled then also in the same order )
    # Turn into set:
    group_set = set({})
    for g in groups:
        group_set.add(tuple(g))
    groups = list(group_set)


    # Now run the main code.
    distinguish_groups_by_covers_parallel(groups, (2,6), csv_out_path, num_workers=num_workers)

    resulting_groups = load_groups_from_csv(csv_out_path) 

    remaining_groups = get_nontrivial_groups(resulting_groups)

    print("We have reduced the number of groups from {} to {}.\n".format(len(groups), len(remaining_groups)))


    print("---------------------------------")

    print("Now we run the computation for the degree 7 covers (This is expected to take longer)")

    sys.stdout.flush()

    csv_out_path_7 = "results2-7.csv"
    distinguish_groups_by_covers_parallel(remaining_groups, (2,7), csv_out_path_7, num_workers=num_workers)

    print("We have completed computing the number of degree 7 covers for the remaining knots.")
    resulting_groups_7 = load_groups_from_csv(csv_out_path_7) 
    remaining_groups_7 = get_nontrivial_groups(resulting_groups_7)

    print("With the deg 7 computations we have reduced the number of groups from {} to {}.".format(len(groups), len(remaining_groups)))

    sys.stdout.flush()
