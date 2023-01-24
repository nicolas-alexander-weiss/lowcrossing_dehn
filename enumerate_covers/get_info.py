from census_csv_tools import *

import ast

def get_num_elements(list_str):
   return len(ast.literal_eval(list_str))

def status(filepath_7, filepath_6):
    # load the results
    old_groups = load_knots_from_csv(filepath_6, columns=["rep", "covers", "group"], delimiter=",")
    groups = load_knots_from_csv(filepath_7, columns=["rep", "covers", "group"], delimiter=",")

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


def join_all_groups(generated_groups):
    """Takes groups as a list of dictionaries representing rows from the results2-n.csv
    Outputs a set!"""
    all_elements_generated = set()
    for g in generated_groups:
        elements = ast.literal_eval(g["group"])
        for e in elements:
            all_elements_generated.add(e)
    return all_elements_generated

def compile_results(filepath_7, filepath_6):
    # rk: The old groups contain the result from the computation of deg 2-6 covers.
    old_groups = load_knots_from_csv(filepath_6, columns=["rep", "covers", "group"], delimiter=",")
    old_non_trivial = [g for g in old_groups if get_num_elements(g["group"]) != 1]

    generated_groups = load_knots_from_csv(filepath_7, columns=["rep", "covers", "group"], delimiter=",")
    all_elements_generated = join_all_groups(generated_groups)
    print("Created a set of all processed knots.")

    # Rk: Some of the groups (4) where not processed, since the computation didn't terminate.
    # Suffices to not find the representative in the generated elements.
    non_processed_groups = [g for g in old_non_trivial if g["rep"] not in all_elements_generated]

    # Compile the left over groups.
    non_resolved_groups = non_processed_groups + [g for g in generated_groups if get_num_elements(g["group"]) != 1]

    # print("#Not processed groups: {}\n".format(len(non_processed_groups)))    
    print("#Not processed groups: {}\n{}".format(len(non_processed_groups), non_processed_groups))


    print("\n#Total unresolved: {}".format(len(non_resolved_groups)))
    
    outfilename = 'groups_of_same_volume_alex_knotFloer_coversdeg7'
    print("Outputting them to file: {}".format(outfilename))

    print_knots_to_csv(non_resolved_groups, columns=["rep", "covers", "group"], csv_file_path= 'groups_of_same_volume_alex_knotFloer_coversdeg7'+'.csv')


if __name__ == "__main__":
    filepath_6 = "results2-6.csv"
    filepath_7 = "results2-7.csv"
    status(filepath_7, filepath_6)

    print("\n-----------------------------\n")
    print("Now compiling the results...")
    compile_results(filepath_7, filepath_6)
