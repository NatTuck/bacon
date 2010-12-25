#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;
use 5.10.0;

my $var = shift;

my $ARCH = `uname -m`;
chomp $ARCH;

my $CL_INC = "";
my $CL_LIB = "/usr/lib";

if ($ENV{ATISTREAMSDKROOT}) {
    my $base = $ENV{ATISTREAMSDKROOT};
    $CL_INC = "$base/include";
    $CL_LIB = "$base/lib/$ARCH";
}

if (-d "/usr/local/cuda") {
    $CL_INC = "/usr/local/cuda/include";
}

given ($var) {
    when ('CL_INC') {
        say $CL_INC;
    }
    when ('CL_LIB') {
        say $CL_LIB;
    }
}
