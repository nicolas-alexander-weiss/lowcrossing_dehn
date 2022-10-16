# Alexander Groups

In this section we sort the lowcrossing knots with 5 to 9 crossings into groups by their Alexander polynomials. We then sort-in the knots from the lists of Burton with 16 - 19 crossings by checking if there exists a knot group with the same polynomial (criterion (a))and furthermore a potential knot, such that the sum of the crossing numbers is leq 25 (criterion (b)).

## Lists

The lists in the folder (/groups/) are named by the first knot in the list.
Hence, their name indicates also the lowest crossing number of a knot in the list. Therefore, if the group file is named "9_17.csv", then the added knots may have at most 16 crossings.

Furthermore, there exists a "distinction_list.csv" which holds for each of the first members of the groups the value on which the comparison is based. Here this is the the alexander polynomial.

## Remark on comparing dicts

So far, I was just dealing with the string representations of the dictionaries. This, however, requires that the string is always generated in the same way. To avoid problems here, the str should first be converted into a dictionary and then be compared.

If we can find out that dict1 == dict2  iff str(dict1) == str(dict2)