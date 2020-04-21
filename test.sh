#!/bin/bash

inputs=./inputs/*.inp
#inputs=./inputs/factory.inp

frames=( 2 10 99 )

exebase=life
outdir=./inputs/frames
expectedoutdir=./inputs/expected-output
outputext=pbm

#===============================================================================

source ./bat/test.sh
echo "? = $?"

