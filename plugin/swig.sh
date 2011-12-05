#!/bin/sh

rm -f idaswig_wrap.cpp
swig $@ -ruby -c++ -w801 -o idaswig_wrap.cpp idaswig.i 2>&1
#swig -small -ruby -c++ -o idaswig_wrap.cpp idaswig.i 2>&1
if [ -e idaswig_wrap.cpp ]; then
	# grrrrr
	sed -i 's/long long/LONG_LONG/g' idaswig_wrap.cpp
	echo "+++ cpp file created"
fi
