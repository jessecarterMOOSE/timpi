#!/bin/bash
#set -e

# You can run this script on a single header file by doing:
# test_CXXFLAGS="`timpi-config --cppflags --cxxflags --include`" HEADERS_TO_TEST=exact_solution.h ./bin/test_headers.sh

# To run this script on *every* header file in an installed TIMPI:
# test_CXXFLAGS="`timpi-config --cppflags --cxxflags --include`" HEADERS_TO_TEST="`find $TIMPI_DIR -name "*.h" -type f -exec basename {} \;`" ./bin/test_headers.sh

# prefix to use when including headers
PACKAGE_PREFIX=timpi

# Respect the JOBS environment variable, if it is set
if [ -n "$JOBS" ]; then
    n_concurrent=$JOBS
else
    n_concurrent=20
fi

#echo MAKEFLAGS=$MAKEFLAGS

# Terminal commands to goto specific columns
rescol=65;

# Terminal commands for setting the color
gotocolumn=;
white=;
green=;
red=;
grey=;
colorreset=;
if (test "X$TERM" != Xdumb && { test -t 1; } 2>/dev/null); then
  gotocolumn="\033["$rescol"G";
  white="\033[01;37m";
  green="\033[01;32m";
  red="\033[01;31m";
  grey="\033[00;37m";
  colorreset="\033[m"; # Terminal command to reset to terminal default
fi


#echo "CXX=$CXX"

testing_installed_tree="no"

if (test "x$test_CXXFLAGS" = "x"); then

    testing_installed_tree="yes"

    if (test "x$PKG_CONFIG" != "xno"); then
        test_CXXFLAGS=`pkg-config timpi --cflags`

    elif (command -v timpi-config); then
        test_CXXFLAGS=`timpi-config --cppflags --cxxflags --include`

    else
        echo "Cannot query package installation!!"
        exit 1
    fi
fi

echo "Using test_CXXFLAGS =" $test_CXXFLAGS

# this function handles the I/O and compiling of a particular header file
# by encapsulating this in a function we can fork it and run multiple builds
# simultaneously
function test_header()
{
    myreturn=0
    header_to_test=$1
    header_name=`basename $header_to_test`
    app_file=`mktemp -t $header_name.XXXXXXXXXX`
    source_file=$app_file.cxx
    object_file=$app_file.o
    errlog=$app_file.log
    stdout=$app_file.stdout

    printf '%s' "Testing Header $header_to_test ... " > $stdout
    echo "#include \"$PACKAGE_PREFIX/$header_name\"" >> $source_file
    echo "int foo () { return 0; }" >> $source_file

    #echo $CXX $test_CXXFLAGS $source_file -o $app_file
    if $CXX $test_CXXFLAGS $source_file -c -o $object_file >$errlog 2>&1 ; then
        # See color codes above.  We:
        # .) skip to column 65
        # .) print [ in white
        # .) print OK in green
        # .) print ] in white
        # .) reset the terminal color
        # .) print a newline
        printf '\e[65G\e[1;37m[\e[1;32m%s\e[1;37m]\e[m\e[m\n' "   OK   " >> $stdout
    else
        # See comment above for OK status
        printf '\e[65G\e[1;37m[\e[1;31m%s\e[1;37m]\e[m\e[m\n' " FAILED " >> $stdout
        echo "Source file:" >> $stdout
        cat $source_file  >> $stdout
        echo ""  >> $stdout
        echo "Command line:" >> $stdout
        echo $CXX $test_CXXFLAGS $source_file -c -o $object_file  >> $stdout
        echo ""  >> $stdout
        echo "Output:" >> $stdout
        cat $errlog >> $stdout
        echo "" >> $stdout
        myreturn=1
    fi

    cat $stdout
    rm -f $source_file $app_file $object_file $errlog $stdout

    return $myreturn
}


if [ "x$HEADERS_TO_TEST" = "x" ]; then
    HEADERS_TO_TEST=$DEFAULT_HEADERS_TO_TEST
fi


# loop over each header and fork tests
returnval=0
nrunning=0
ntotal=0
runninglist=""
for header_to_test in $HEADERS_TO_TEST ; do
    if [ $nrunning -ge $n_concurrent ]; then
        for pid in $runninglist ; do
            wait $pid
            # accumulate the number of failed tests
            returnval=$(($returnval+$?))
        done
        nrunning=0
        runninglist=""
    fi

    test_header $header_to_test &
    runninglist="$runninglist $!"
    nrunning=$(($nrunning+1))
    ntotal=$(($ntotal+1))
done

for pid in $runninglist ; do
    wait $pid
    returnval=$(($returnval+$?))
done

echo "$returnval failed tests of $ntotal header files"

exit $returnval
