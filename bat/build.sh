#!/bin/bash

io=0
this=$(basename ${BASH_SOURCE[0]})
thisdir=$(dirname ${BASH_SOURCE[0]})
source "${thisdir}/constants.sh"
source "${thisdir}/os.sh"

BTYPE=Release

for arg in "$@" ; do
	#echo $arg
	if [[ "$arg" == "Release" ]] ; then
		BTYPE=Release
	elif [[ "$arg" == "Debug" ]] ; then
		BTYPE=Debug
	else
		echo "Warning: unknown cmd argument '$arg'"
		echo
	fi
done

echo "Using build type $BTYPE"
mkdir -p "$build"
pushd "$build"

#which gfortran

if [[ -x "$(which cmake)" ]]; then
	CMAKE=cmake
else
	CMAKE="/c/Program Files/cmake/bin/cmake.exe"
fi

# CMake runs from the top-level folder
if [[ "$machine" == "MinGw" ]]; then
	"$CMAKE" .. -DCMAKE_BUILD_TYPE=$BTYPE -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -G "MSYS Makefiles"
else
	"$CMAKE" .. -DCMAKE_BUILD_TYPE=$BTYPE -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON
fi

"$CMAKE" --build . --config $BTYPE || io=-1

# from build
popd

exit $io

