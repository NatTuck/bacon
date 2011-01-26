#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use IO::Handle;

my ($INCDIR) = @ARGV;

unless (defined $INCDIR && $INCDIR =~ /include/) {
    say "Usage: $0 sdk-include-directory";
    exit(0);
}

my %CODES = ();

open my $clh, "<", "$INCDIR/CL/cl.h";
while (<$clh>) {
    next unless /^#define\s+(CL_\w+)\s+(-?\d+)/;
    my ($code, $symbol) = ($2, $1);
    next if ($code == 0 || $code == 1);

    $CODES{$code} = $symbol;
}
close $clh;

open my $clcc, ">", "cl_perror.cc";
$clcc->print(<<"HEAD");

// This file is generated automatically.
// Any changes you make will be lost.

#include <string>
using std::string;

#include <iostream>
using std::cerr;
using std::endl;

#include "cl_perror.hh"

string
cl_strerror(int code)
{
    switch (code) {
HEAD

for my $code (reverse sort { $a <=> $b } keys %CODES) {
    my $symbol = $CODES{$code};
    $clcc->print(qq{    case $code:\n});
    $clcc->print(qq{        return string("$symbol");\n});
}

$clcc->print(<<"FOOT");
    default:
        return string("UNKNOWN_ERROR_CODE");
    };
}

void
cl_perror(int code)
{
    cerr << "OpenCL error: " << cl_strerror(code) << endl;
}
FOOT
close $clcc;

open my $clhh, ">", "cl_perror.hh";
$clhh->print(<<"HEADER");
#ifndef CL_PERROR_HH
#define CL_PERROR_HH

// This file is generated automatically.
// Any changes you make will be lost.

#include <string>

std::string cl_strerror(int code);
void cl_perror(int code);

#endif
HEADER
close $clhh;
