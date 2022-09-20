# Low Crossing Knots with K(0,1) = K'(0,1)
Finding two low crossing knots with the same (0,1) Dehn filling is of interests into to find potential candidates
which might serve as counter examples to the 4-dim Poincare Conjecture [https://arxiv.org/abs/2102.04391]. 
(Here the slopes are always measured w.r.t. the Seifert framing of the knot.)

It is of interest to find out what, given all pairs of knots K, K' with the same (0,1) filling, the minimum
of c(K) + c(K') is. Here c(K) denotes the crossing number of K.

It is known that for 5_2=K5a1 an equality of Dehnfillings K5_2(0,1) = K'(0,1) implies K = K'. [Theorem 1.11 in https://arxiv.org/abs/2208.03307]
Furthermore, it is known that any slope of the unknot, the trefoil and the figure eight knot is characterizing. [https://arxiv.org/abs/math/0310164, https://arxiv.org/abs/math/0604079]
Furthermore, an example of two knots with distinct filling was found in [Example 4.10 in https://arxiv.org/abs/2102.04391], such that c(K) + c(K') = 26. This is K12n309(0,1)= m(K14n14254)(0,1).

Thus, the minimum such sum must lie in the interval [11, 26].

In this repository, we want to determine whether an example of a better pairing can be found between a knot of 
crossing number 16, 17, 18, or 19 and a corresponding knot of crossing number 6, 7, 8 or 9 (respectively).

## Procedure
1. Group the low and higher crossing knots by the Alexander polynomial.
2. Decrease the group size further by using further obstructions P of the kind:  K(0,1) = K'(0,1) => P(K)=P(K').

COMMENT: The knot K5a1 does not need to be considered.
