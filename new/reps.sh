#!/bin/bash

N="$1"
k="$2"

for i in {1..5}
do
   julia work_sim.jl $N $k $i &
done
