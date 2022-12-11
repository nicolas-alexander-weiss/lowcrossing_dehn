"""
@author: Nicolas Weiss
@created: 2022-12-11

@goal: Use Burton's implementation within Regina to compute (in parallel) the number of covers
for the not yet distinguished 0-fillings.

@software: Regina 7.2
"""

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

def compute_covers_zero_surgery(census_name):
    M = snappy.Manifold(census_name)
    M.dehn_fill((0,1))
    M_reg = Triangulation3(M)
    group = M_reg.group()
    num_covers = [len(group.enumerateCovers(i)) for i in range(2,8)]
    
    return num_covers

if __name__ == "__main__":

    print("Result (num covers, index from 2 to 7)")
    for idx, pair in enumerate(probably_equal):
        name1 = pair[0][0]
        name2 = pair[1][0]

        cov1 = compute_covers_zero_surgery(name1)
        cov2 = compute_covers_zero_surgery(name2)

        print("\nPair {}".format(idx))
        print("{}(0,1): {}".format(name1, cov1))
        print("{}(0,1): {}".format(name2, cov2))