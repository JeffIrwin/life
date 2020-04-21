#!/bin/bash

io=0

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac
echo ${machine}

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
TARGET=target
mkdir -p $TARGET
pushd $TARGET

#which gfortran

if [[ -x "$(which cmake)" ]]; then
	CMAKE=cmake
else
	CMAKE="/c/Program Files/cmake/bin/cmake.exe"
fi

if [[ "$machine" == "MinGw" ]]; then
	"$CMAKE" .. -DCMAKE_BUILD_TYPE=$BTYPE -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -G "MSYS Makefiles"
else
	"$CMAKE" .. -DCMAKE_BUILD_TYPE=$BTYPE -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON
fi

"$CMAKE" --build . --config $BTYPE || io=-1

# from TARGET
popd

exit $io

