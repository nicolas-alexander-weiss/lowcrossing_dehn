from census_csv_tools import *

import ast

def get_num_elements(list_str):
   return len(ast.literal_eval(list_str))

def status(filepath, filepath_6):
    # load the results
    old_groups = load_knots_from_csv(filepath_6, columns=["rep", "covers", "group"], delimiter=",")
    groups = load_knots_from_csv(filepath, columns=["rep", "covers", "group"], delimiter=",")

    # statistics on the deg6 results.
    non_singleton_6 = [get_num_elements(g["group"]) for g in old_groups if get_num_elements(g["group"]) != 1]
    num_elements_without_singltons = sum(non_singleton_6)
    
    print("Non_singleton_6: {}".format(len(non_singleton_6)))
    print("Average group_size {}\n\n".format(num_elements_without_singltons / len(non_singleton_6)))

    #    print(groups[:10])
    #print(get_num_elements(groups[0]["group"]))
    num_groups = len(groups)
    num_singletons = len([g for g in groups if get_num_elements(g["group"]) == 1])

    print("Stats on the output groups:")
    print("num groups: {}\nnum singletons: {}\n non-singleton: {}".format(num_groups, num_singletons, num_groups - num_singletons))

if __name__ == "__main__":
    filepath_6 = "results2-6.csv"
    filepath = "results2-7.csv"
    status(filepath, filepath_6)
