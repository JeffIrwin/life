#!/bin/bash

inputs=./inputs/*.json
#inputs=./inputs/factory.inp

frames=( 2 10 99 )

exebase=life
outdir=./inputs/frames
expectedoutdir=./inputs/expected-output
outputext=pbm
use_stdin="false"

#===============================================================================

source ./submodules/bat/test.sh

