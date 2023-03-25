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
crossing number 16, 17, 18, or 19 and a corresponding knot of crossing number 6, 7, 8 or 9 (respectively).

## Procedure
1. Group the low and higher crossing knots by the Alexander polynomial.
2. Decrease the group size further by using further obstructions P of the kind:  K(0,1) = K'(0,1) => P(K)=P(K').

## COMMENTS:
1. The knot 5_2=K5a1 has 0 as a characterizing slope and thus does not need to be considered. So I guess you can remove that knot from your list.
2. I started a careful computation of the census knots. I think we should be able to rather quickly completely classify all census knots with the same 0-surgeries. And this computations might serve as a blueprint for what we want to do with the low-crossing knots. The notebook is uploaded. We can check the remaining knots via regina. 
3. There is another recent paper (https://arxiv.org/pdf/2211.04280.pdf) that shows that several low-crossing knots have 0 as characterizing slope. We can use that results and their methods later.
4. We have not found any pairs of knots with the same Alexander polynomials where one of the knots is alternating. However, such pairs exist among 2-bridge knots: https://arxiv.org/pdf/2105.13897.pdf And then even all their quantum invariants are the same. We should also analyze and mention these examples.
5. It might still be true that knots with the same 0-surgery have the same knot floer homology. We should try to further analyze this.

## RESULTS OBTAINED SO FAR:
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
 
 (2)  The following list of census knots might have equal non-hyperbolic 0-surgeries:
  [[['o9_33067',
   "JSJ([('SFSpace', 'SFS [A: (2,1)]'), ('SFSpace', 'SFS [A: (3,2)]')])"],
  ['o9_34323',
   "JSJ([('SFSpace', 'SFS [A: (2,3)]'), ('SFSpace', 'SFS [A: (3,5)]')])"]],
 [['o9_27542', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm015')])"],
  ['o9_33568', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm015')])"]],
 [['o9_31828', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm032')])"],
  ['o9_37768', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm032')])"]]]
  
  (3) All other census knots have different 0-surgeries.
  
  (4) The following list of low-crossings knots have equal hyperbolic 0-surgeries:
  [['K12n309', 'K14n14254'],
 ['K11n49', 'K15n103488'],
 ['K13n572', 'K15n89587'],
 ['K13n1021', 'K15n101402'],
 ['K13n2527', 'K15n9379']]
 
 (5) The following list has all pairs of knots with at most 15 crossings that might share the same non-hyperbolic 0-surgery.
  [[['K5a1', 'SFS [A: (2,1)] / [ 0,1 | 1,-1 ]'],
  ['K15n43522', 'SFS [A: (2,1)] / [ 3,11 | 2,7 ]']],
 [['K5a2', 'SFS [S2: (2,1) (5,2) (10,-9)]'],
  ['K10n13', 'SFS [S2: (2,1) (5,1) (10,-7)]']],
 [['K9a36',
   "JSJ[('SFSpace', 'SFS [A: (2,3)]'), ('SFSpace', 'SFS [A: (3,1)]')]"],
  ['K13a3143', 'SFS [A: (6,5)] / [ 0,1 | 1,-1 ]']],
 [['K9n5', 'SFS [A: (2,1)] / [ -1,3 | 1,-2 ]'],
  ['K15n112479', 'SFS [A: (2,1)] / [ 2,9 | 1,4 ]']],
 [['K10a117',
   "JSJ[('SFSpace', 'SFS [A: (2,1)]'), ('SFSpace', 'SFS [A: (3,5)]')]"],
  ['K14a12741', 'SFS [A: (6,1)] / [ 0,1 | 1,-2 ]']],
 [['K15n19499',
   "JSJ[('SFSpace', 'SFS [D: (2,1) (2,-1)]'), ('hyperbolic', 'm032')]"],
  ['K15n153789',
   "JSJ[('SFSpace', 'SFS [D: (2,1) (2,-1)]'), ('hyperbolic', 'm032')]"]]]
 
(6) We have 40328 groups of knots with the same Alexander-polynomials such that their 0-fillings are hyperbolic and share the same volume and such that their knot Floer homology invariants agree (fiberedness status, genus, and rank in Alexander grading=genus). The results are in the text or pickle file with the name: groups_of_same_volume_alex_knotFloer

(7) All knots with at most 15 crossings are such that: K(0,1)!=(mK)(0,1).

(8) We also compared the census knots with knots of at most 15 crossings:
We found 3 pairs: [['t12270', 'K13n2527'], ['t11462', 'K14n3155'], ['o9_40081', 'K15n94464']]
One knot that might share the 0-surgery with a connected sum:
['o9_37563', 'K3a1+sum+K5a2', 'SFS [D: (2,1) (3,2)] U/m SFS [D: (2,1) (5,2)], m = [ -3,4 | -2,3 ]']
And 12 more possible pairs:
[[['m201', 'SFS [S2: (2,1) (5,1) (10,-7)]'],
  ['K5a2', 'SFS [S2: (2,1) (5,2) (10,-9)]']],
 [['o9_34818', 'SFS [S2: (2,1) (5,1) (10,-7)]'],
  ['K5a2', 'SFS [S2: (2,1) (5,2) (10,-9)]']],
 [['s188', 'SFS [S2: (3,1) (4,1) (12,-7)]'],
  ['K8n3', 'SFS [S2: (3,2) (4,1) (12,-11)]']],
 [['o9_22337',
   'SFS [D: (2,1) (3,1)] U/m SFS [D: (2,1) (6,5)], m = [ -2,3 | -1,2 ]'],
  ['K15n124802',
   'SFS [D: (2,1) (3,1)] U/m SFS [D: (2,1) (6,1)], m = [ -7,9 | -3,4 ]']],
 [['v0595', 'SFS [S2: (2,1) (7,2) (14,-11)]'],
  ['K7a7', 'SFS [S2: (2,1) (7,3) (14,-13)]']],
 [['t12120', 'SFS [S2: (2,1) (7,2) (14,-11)]'],
  ['K7a7', 'SFS [S2: (2,1) (7,3) (14,-13)]']],
 [['t01142', 'SFS [S2: (3,1) (5,2) (15,-11)]'],
  ['K10n21', 'SFS [S2: (3,1) (5,3) (15,-14)]']],
 [['t02019', 'SFS [S2: (2,1) (9,2) (18,-13)]'],
  ['K9a41', 'SFS [S2: (2,1) (9,4) (18,-17)]']],
 [['o9_04139', 'SFS [S2: (3,1) (7,2) (21,-13)]'],
  ['K14n21881', 'SFS [S2: (3,2) (7,2) (21,-20)]']],
 [['o9_04950', 'SFS [S2: (2,1) (11,3) (22,-17)]'],
  ['K11a367', 'SFS [S2: (2,1) (11,5) (22,-21)]']],
 [['o9_31828', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm032')])"],
  ['K15n153789',
   "JSJ[('SFSpace', 'SFS [D: (2,1) (2,-1)]'), ('hyperbolic', 'm032')]"]],
 [['o9_37768', "JSJ([('SFSpace', 'M/n2 x~ S1'), ('hyperbolic', 'm032')])"],
  ['K15n153789',
   "JSJ[('SFSpace', 'SFS [D: (2,1) (2,-1)]'), ('hyperbolic', 'm032')]"]]]

## TO DO:
- For the remaining pairs in lists (2) and (5) use regina to perform a search through the Pachner graph to find equal triangulations.
- Use Regina to compute the number of index n subgroups (for small n) of the 0-fillings of the knots in list (6). This should reduce the number of possible pairs significantly. Such that we are able to work more refined with the smaller list.
- Show that 5_1 has no partner with 20 crossings. (Use the new classification for that.)
