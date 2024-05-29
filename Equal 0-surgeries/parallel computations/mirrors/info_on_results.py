"""
@author: Nicolas Weiss
@created: 2024-04-06

@goal: Give statistics on the results of the computation
"""

import csv

if __name__ == "__main__":

    # original input knots:
    original_inputs_csv ="../../vanishing_signature_hyp.csv"
    knots_vanishing_signature_list = []
    with open(original_inputs_csv, "r") as infile:
        for line in infile:
            knots_vanishing_signature_list.append(line.strip())
    knots_vanishing_signature = set(knots_vanishing_signature_list)
    print("Num input knots: {}".format(len(knots_vanishing_signature_list)))
    print("As set: {}\n".format(len(knots_vanishing_signature)))


    # Load the results:
    results_csv = "results_zs_isotopic_to_mirror.csv"
    results = []
    with open(results_csv, "r") as inputfile:
        reader = csv.DictReader(inputfile, fieldnames=["knot","symmetry_group","verified","amphichiral"])
        for row in reader:
            if row["knot"] == "knot":
                continue
            results.append(row)

    # Timed out previously:
    csv_timed_out_1min = "timed_out_knots_1min.csv"
    timed_out_1min = []
    with open(csv_timed_out_1min, "r") as infile:
        reader = csv.DictReader(infile, ["knot"])
        for row in reader:
            timed_out_1min.append(row["knot"])

    print("Num computed knots (symmetry group): {}\nKnots timed out after 1 min: {}".format(len(results), len(timed_out_1min)))
    print("Length as set (results): {}".format(len(set([k["knot"] for k in results]))))
    print("Length as set (timed_out_1min): {}".format(len(set(timed_out_1min))))


    csv_timed_out_5min = "timed_out_knots_5min.csv"
    timed_out_5min = []
    with open(csv_timed_out_5min, "r") as infile:
        reader = csv.DictReader(infile, ["knot"])
        for row in reader:
            timed_out_5min.append(row["knot"])

    print("(thereof) Knots timed out after 5 min: {}".format(len(timed_out_5min)))
    print("Length as set (timed_out_5min): {}\n".format(len(set(timed_out_5min))))


    num_verified = 0
    num_verified_amphichiral_symmetry_group = 0
    verified_amphichiral = []
    for result in results:
        if result["verified"] == "True":
            num_verified += 1
            if result["amphichiral"] == "True":
                num_verified_amphichiral_symmetry_group += 1
                verified_amphichiral += [result["knot"]]

    print("Num_verified: {} (thereof amphichiral: {}), Not Verified {}".format(num_verified, num_verified_amphichiral_symmetry_group, len(results) - num_verified))
    print("The list of verified amphichiral knots is: {}".format(verified_amphichiral))

    print("Determining the knots that are unclear (i.e. in the timed_out_1min list or timed_out_5min list, but not computed.)")
    unclear = set(timed_out_1min).difference(set([k["knot"] for k in results]))
    print("unclear: {}".format(len(unclear)))


    print("\nVerifying that all knots that went into this process from '{}' have been computed (in '{}') or are in '{}' now.".format(
        "../../vanishing_signature_hyp.csv",
        "results_sz_isotopic_to_mirror.csv",
        "unclear_knots.csv"
    ))

    set_difference = knots_vanishing_signature.difference(set([k["knot"] for k in results])).difference(unclear)
    set_equality = knots_vanishing_signature.difference(set([k["knot"] for k in results])) == unclear

    print("set difference (vanishing_sig_hyp - results_sz - unclear): {}".format(set_difference))
    print("set equality (vanishing_sig_hyp - results_sz == unclear ): {}".format(set_equality))