#!/bin/bash

SCRIPT_PATH=$(readlink -f $BASH_SOURCE)

export BACON_BASE=$(dirname $SCRIPT_PATH)
export LD_LIBRARY_PATH="$BACON_BASE/lib:$LD_LIBRARY_PATH"
export PERL5LIB="$BACON_BASE/perl:$PERL5LIB"
export PATH="$BACON_BASE/bin:$PATH"
