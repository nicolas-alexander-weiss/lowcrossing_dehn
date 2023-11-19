# Low Crossing Knots with K(0,1) = K'(0,1)
Finding two low crossing knots with the same (0,1) Dehn filling is of interests into to find potential candidates
which might serve as counter examples to the 4-dim Poincare Conjecture [https://arxiv.org/abs/2102.04391]. 
(Here the slopes are always measured w.r.t. the Seifert framing of the knot.)

It is of interest to find out what, given all pairs of knots K, K' with the same (0,1) filling, the minimum
of c(K) + c(K') is. Here c(K) denotes the crossing number of K.

It is known that for 5_2=K5a1 an equality of Dehnfillings K5_2(0,1) = K'(0,1) implies K = K'. [Theorem 1.11 in https://arxiv.org/abs/2208.03307, cf. https://arxiv.org/pdf/2209.09805.pdf]
Furthermore, it is known that any slope of the unknot, the trefoil and the figure eight knot is characterizing. [https://arxiv.org/abs/math/0310164, https://arxiv.org/abs/math/0604079]
Furthermore, an example of two knots with the same 0-filling was found in [Example 4.10 in https://arxiv.org/abs/2102.04391], such that c(K) + c(K') = 26. This is K12n309(0,1)= m(K14n14254)(0,1).

Thus, the minimum such sum must lie in the interval [11, 26].

In this repository, we want to determine whether an example of a better pairing can be found between a knot of 
crossing number 16, 17, 18, 19, or 20 and a corresponding knot of crossing number 5, 6, 7, 8, or 9 (respectively).

## Procedure
1. Group the low and higher crossing knots by the Alexander polynomial.
2. Decrease the group size further by using further obstructions P of the kind:  K(0,1) = K'(0,1) => P(K)=P(K').

## RESULTS OBTAINED:
(1) The following list of census knots have equal hyperbolic 0-surgeries:

[['m199', 'o9_34801'],
 ['m224', 'v3093'],
 ['v3423', 'v3536'],
 ['v3423', 'o9_42735'],
 ['v3536', 'o9_42735'],
 ['t12607', 't12748'],
 ['o9_41909', 'o9_42515'],
 ['v2508', 'v3195'],
 ['t11532', 't12200'],
 ['t11532', 'o9_43446'],
 ['t12200', 'o9_43446'],
 ['o9_39433', 'o9_40519'],
 ['v2869', 't12388'],
 ['t07281', 'o9_34949'],
 ['t07281', 'o9_39806'],
 ['o9_34949', 'o9_39806'],
 ['t10974', 'o9_39967'],
 ['t09735', 't11748'],
 ['t09900', 'o9_34908'],
 ['t09900', 'o9_43876'],
 ['o9_34908', 'o9_43876'],
 ['t11900', 'o9_40803'],
 ['o9_33833', 'o9_37547']]
 
 (2)  The following list of census knots have equal non-hyperbolic 0-surgeries:
 
[['o9_27542', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm015')])"],
 ['o9_33568', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm015')])"]],
[['o9_31828', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm032')])"],
 ['o9_37768', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm032')])"]]]
  
  (3) All other census knots have different 0-surgeries.
  
  (4) The following list of low-crossing knots have equal hyperbolic 0-surgeries:
  
  [['K12n309', 'K14n14254'],
 ['K11n49', 'K15n103488'],
 ['K13n572', 'K15n89587'],
 ['K13n1021', 'K15n101402'],
 ['K13n2527', 'K15n9379']]
 
 (5) The following list has all pairs of knots with at most 15 crossings that share the same non-hyperbolic 0-surgery.
 
 [['K15n19499',"JSJ[('SFSpace', 'SFS [D: (2,1) (2,-1)]'), ('hyperbolic', 'm032')]"],
 ['K15n153789',"JSJ[('SFSpace', 'SFS [D: (2,1) (2,-1)]'), ('hyperbolic', 'm032')]"]]]


(6) All knots with at most 15 crossings are such that: K(0,1)!=(mK)(0,1).

(7) We also compared the census knots with knots of at most 15 crossings:
We found 3 pairs with hyperbolic equal 0-surgeries: 

[['t12270', 'K13n2527'], ['t11462', 'K14n3155'], ['o9_40081', 'K15n94464']]

and 3 pairs with non-hyperbolic equal 0-surgeries:

[['o9_31828', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm032')])"],
 ['K15n153789',"JSJ[('SFSpace', 'SFS [D: (2,1) (2,-1)]'), ('hyperbolic', 'm032')]"]],
[['o9_37768', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm032')])"],
 ['K15n153789',"JSJ[('SFSpace', 'SFS [D: (2,1) (2,-1)]'), ('hyperbolic', 'm032')]"]],
[['o9_31828', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm032')])"],
 ['K15n19499',   "JSJ[('SFSpace', 'SFS [D: (2,1) (2,-1)]'), ('hyperbolic', 'm032')]"]]]

