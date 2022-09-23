"""
@created: 2022-09-20

@author: Nicolas Alexander Weiss

@goal: Sort the lower crossing knots (5-9) and higher crossing knots (16-19) 
        by their Alexander polynomial.

@software: snappy

@remark: "group" might not the best term to be overloaded here.

"""

from tokenize import group
import snappy
from census_csv_tools import *

def create_low_crossing_groups():
    # get the low_crossing_knots with crossings upto :
    low_crossing_knots = []
    for n in (5,6,7,8,9):
        low_crossing_knots += snappy.LinkExteriors(knots_vs_links="knots", crossings=n)
    
    print("There are {} knots of crossing number 5-9".format(len(low_crossing_knots)))

    groups = {}

    for k in low_crossing_knots:
        name = k.name()
        alexander = k.alexander_polynomial()
        alex_dict_str = str(alexander.dict())

        if not alex_dict_str in groups.keys():
            groups[alex_dict_str] = []
        
        groups[alex_dict_str].append({"knot":name, "crossings":len(k.link().crossings)})
    
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

def get_all_alexander_groups():
    pass


if __name__ == "__main__":
    # create_low_crossing_groups()
    pass