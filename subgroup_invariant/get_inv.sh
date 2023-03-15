#!/bin/sh

gap -r -b -q subgroup_invariant.g << EOI
ComputeInvariant( "$1" , "$2" , "$3" , $4);
quit;
EOI