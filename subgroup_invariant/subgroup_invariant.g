#
# Test: Compute the subgroup invariant for the m004 knot
#

# Toggle this if desired to have the example run as well.
#
verbose := false;

# 1) Setup the group 
#
# Generators:
#    a,b
# Relators:
#    aaabABBAb

if verbose then
    Print("\nWe consider the following example data:", "\n");

    example_gens := ["a", "b"];
    example_rel_str := "aaabABBAb";

    Print("Generators: ", example_gens, "\n");
    Print("Relations: ", example_rel_str, "\n");
fi;

# Should create a function which constructs the group given ["a","b"] and "rel1=rel2=1" or "rel1" only.
#
# Call the below with CreateGroup(["a","b"], "aaabABBAb")

CreateGroup := function(gen_list, rel_str)
    local f, gens, r;
    f := FreeGroup(gen_list);
    gens := GeneratorsOfGroup(f);
    r := ParseRelators(gens, rel_str); 
    return f/r;
end;

if verbose then
    Print("\nWe consider the group g = FreeGroup(gens)/rels", "\n");
    example_group := CreateGroup(example_gens, example_rel_str);
fi;

# Compute the abelianization, via AbelianInvariants(g)
# This goes through the generators of the abelianization and denotes the order, 0 if infinite.
#
# For example: AbelianInvariants(CreateGroup(["a","b", "c"], "aaaa=bb=1")) = [0, 2, 4]
# This way we can quickly compare abelianizations as lists.

if verbose then
    Print("Its abelianization is described by: ", AbelianInvariants(example_group), "\n");
    Print("This means that the abelianization of g is a free groups of rank 1\n\n");
fi;

# 2) Now construct the iterator for conjugacy classes of subgroups upto index n;

if verbose then
    example_max_index := 5;
    example_subgroup_iterator := LowIndexSubgroupsFpGroupIterator(example_group, example_max_index);

    # Remark: For debugging, we might want to have some verbosity in finding these subgroups:
    SetInfoLevel(InfoFpGroup, 2);

    Print("Construct all the subgroups:\n");
    example_subgroups := LowIndexSubgroupsFpGroup(example_group, example_max_index);

    ex_number := 6;
    example_subgroup := example_subgroups[ex_number];

    SetInfoLevel(InfoFpGroup, 0);
fi;

# In our case get the following output:
#I   class 1 of index 1, quotient size 1
#I   class 2 of index 2, quotient size 2
#I   class 3 of index 3, quotient size 3
#I   class 4 of index 4, quotient size 4
#I   class 5 of index 5, quotient size 5
#I   class 6 of index 5, quotient size 120
#I   class 7 of index 4, quotient size 12
#I   class 8 of index 5, quotient size 120
#I   class 9 of index 5, quotient size 10
#
#
#  Q: What is the meaning of the quotient here when the subgroup is not normal perhaps. 
#       Shouldn't quotient size equal the index?
#       Idea: Suppose that the quotient here then G/max_normal_subgroup(H).
#
#  I.e. max_normal_subgroup in H is the "Core of H in G", and given by \Cap gHg^{-1}. i.e.
#  the intersection of all the conjugacy classes.
#
#   A: Trying this out seems to confirm our guess!
#

# 3) Construct the invariant:
#

SubgroupInvariant := function(G, H)
    local C;
    C := Core(G,H);
    return [Index(G,H), Index(G,C), AbelianInvariants(H), AbelianInvariants(C)];
end;

if verbose then
    invariant := SubgroupInvariant(example_group, example_subgroup);

    Print("\nInvariant of the example subgroup (number ", ex_number, "): ", invariant, "\n\n");
fi;

TotalSubgroupInvariantFpGroup := function(G, max_index)
    local total_invariant, subgroup;

    total_invariant := [];
    for subgroup in LowIndexSubgroupsFpGroupIterator(G, max_index) do
        Append(total_invariant, [SubgroupInvariant(G,subgroup)]);
    od;
    return total_invariant;
end;


if verbose then
    # The total invariant, for all subgroups:
    total_invariant := TotalSubgroupInvariantFpGroup(example_group, example_max_index);

    Print("The total invariant for our example group: \n", total_invariant, "\n");
fi;


# 4) Further steps: 
# The output I should then take to python where I do the comparison as sets..
# Idea: Perhaps I can run this script with a certain representation as input and then continue using it
#       within Python.
# 

#
# Approach: Process a CSV file of group presentations
#

# Note: The analog of dictionaries within GAP are "records":
#
#   date := rec(year:= 1997, month:= "Jul", day := 14);
#
# So we can read in a CSV file to get a list of records from it:

ComputeInvariant := function(gen_str, rel_str, split_str, max_index)
    local group;
    #
    # Assume gen_str is e.g. "a_b_c;"
    # Assume rel_str is e.g. "1=aabb=abc"
    
    group := CreateGroup(SplitString(gen_str, "_"), rel_str);
    return TotalSubgroupInvariantFpGroup(group, max_index);
end;


