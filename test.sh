#!/bin/bash

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac
echo ${machine}

./clean.sh
./build.sh
pwd=$(pwd)

echo "==============================================================================="
echo ""
echo "Running tests..."
echo ""

nfail=0
ntotal=0

for i in ./inputs/*.inp; do

	d=$(dirname "$i")

	ib=$(basename $i)

	# Check two different frames
	p02="frames/${ib%.inp}_2.pbm"
	p10="frames/${ib%.inp}_10.pbm"

	#echo "i   = $i"
	#echo "ib  = $ib"
	#echo "p02 = $p02"
	#echo "p10 = $p10"
	#echo "d   = $d"
	#echo ""

	pushd $d

	ntotal=$((ntotal + 1))
	rm "$p02"
	rm "$p10"
	${pwd}/life.exe < "$ib"

	if [[ "$?" != "0" ]]; then
		nfail=$((nfail + 1))
		echo "test.sh:  error:  cannot run test $i"
	fi

	popd

	diff ./inputs/expected-output/$(basename $p02) ./inputs/$p02 > /dev/null
	if [[ "$?" == "1" ]]; then
		nfail=$((nfail + 1))
		echo "test.sh:  error:  difference in $i"
	else

		diff ./inputs/expected-output/$(basename $p10) ./inputs/$p10 > /dev/null
		if [[ "$?" == "1" ]]; then
			nfail=$((nfail + 1))
			echo "test.sh:  error:  difference in $i"
		fi

	fi

done

echo ""
echo "==============================================================================="
echo ""
echo "Total number of tests  = $ntotal"
echo "Number of failed tests = $nfail"
echo "Done!"
echo ""

exit $nfail
