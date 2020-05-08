#!/bin/bash

inputs=./inputs/*.json
#inputs=./inputs/factory.inp

frames=( 2 10 99 )

# "ppm" or "pbm"
outputext=p[pb]m

exebase=life
outdir=./inputs/frames
expectedoutdir=./inputs/expected-output
use_stdin="false"

#===============================================================================

source ./submodules/bat/test.sh

