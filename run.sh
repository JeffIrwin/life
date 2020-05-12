#!/bin/bash

pushd inputs

../build/life.exe acorn.json || exit -1

popd

