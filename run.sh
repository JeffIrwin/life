#!/bin/bash

pushd inputs

../life.exe < acorn.inp || exit -1
ffmpeg -i ./frames/acorn_%d.pbm -c:v libx264 -pix_fmt yuv420p acorn-out-0.mp4 -y || exit -2

popd

