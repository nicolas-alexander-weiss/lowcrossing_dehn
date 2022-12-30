"""
@created: 2022-07-19
@author: Nicolas Weiss

@goal: Making a collection of tools for dealing with the knot data.
"""


import csv

#############################
# Making a dataframe for Census Knot Data
#

def get_dict_of_census_knots(special_keys = []):
    """
        From some existing CSV file, composes a dict of knots with empty data:
        
        --> {"knot1":{"knot":"knot1", "special_key1": "", "special_key2": "",..,}, {...},...}
    """
    nomenclature_csv = "../../nomenclature/nomenclature.csv"
    knots = load_knots_from_csv(nomenclature_csv)

    census_knots = {knot["knot"]:{key:"" for key in special_keys} for knot in knots}
    for k in census_knots.keys():
        census_knots[k]["knot"] = k
    
    return census_knots

#############################
# Lists of dicts vs dict of dicts.
#
def list_of_knots_to_dict(knot_list, index_name):
    """
        knot_list: Uniform list of dictionaries (all with same keys)
        index_name: The key, by wich the knots should be accessed.

        Takes [{"knot":..., "crossings":..,}, {....}]
        and turns it into {"knot1":{...}, "knot2":{...}}
        where the internal dicts hold the same data as before.
    """

    assert(index_name in knot_list[0].keys())

    return {knot[index_name] : knot for knot in knot_list}

def dict_of_knots_to_list(knot_dict):
    """
        Simply truncates the key, and makes a list of the data.

        {"knot1":{..}, "knot2":{..}} -> [{...}, {...}]
    """

    return [knot_dict[k] for k in knot_dict.keys()]


############################
#  For dealing with CSV data
#

def rename_list_of_dicts(dicts, old_keys, new_keys):
    assert(len(old_keys) == len(new_keys))

    for j in range(0, len(dicts)):
        dicts[j] = {new_keys[i] : dicts[j][old_keys[i]] for i in range(0, len(old_keys))}

def sorted_list_of_knots(knot_list):
    assert("knot" in knot_list[0].keys())
    
    # correct order: m, s, v, t, o

    # making sure that the order will be correct!
    key_function = lambda knot : knot["knot"].replace("m", "A").replace("s", "B").replace("v", "C").replace("t", "D").replace("o", "E")

    return sorted(knot_list, key=key_function)


def load_first_column_as_set(csv_path, columns, delimiter):
    """ Loads the csv_file and returns the first column as a set.
    """
    first_column_set = set({})
    with open(csv_path, newline='') as file:
        reader = csv.DictReader(file, delimiter=delimiter, fieldnames=columns, skipinitialspace=True)
        for row in reader:
            # skip first line if it is header
            if row[columns[0]] == columns[0]:
                continue
            first_column_set.add(row[columns[0]])
    
    return first_column_set

def load_knots_from_csv(csv_file_path, columns=[], delimiter=","):
    """
    columns: e.g. ["knot", "small_large"]  (the colums )
    
    returns a list with entries [{"knot":..., "small_large":...},...]

    --> If columns are not specified, it will infer it from the first row.
    """
    knots = []
    with open(csv_file_path, newline='') as file:

        if columns != []:
            reader = csv.DictReader(file, delimiter=delimiter, fieldnames=columns, skipinitialspace=True)
            for row in reader:
                # skip first line if it is header
                if row[columns[0]] == columns[0]:
                    continue
                knots.append(row)
        else:
            reader = csv.DictReader(file, delimiter=delimiter, skipinitialspace=True)
            knots = [row for row in reader]
    
    return knots

def print_knots_to_csv(knots, columns, csv_file_path, delimiter=","):
    """
    fields: e.g. ["knot", "small_large"]  (the colums )
    
    Takes a list of knot dicts as above and prints them to a csv file.
    """
    with open(csv_file_path, "w", newline='') as file:
        writer = csv.DictWriter(file, fieldnames=columns, delimiter=delimiter)

        writer.writeheader()
        for knot in knots:
            writer.writerow(knot)


if __name__ == "__main__":
    #
    # Test

    
    census_knots = get_dict_of_census_knots(special_keys=["homogeneity", "reason"])
    #print(census_knots)

    census_list = dict_of_knots_to_list(census_knots)

    print_knots_to_csv(census_list, ["knot", "reason", "homogeneity"], "knot.csv")