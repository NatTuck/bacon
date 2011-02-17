#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use FindBin qw($Bin);
chdir "$Bin/..";

my $ldpath = "";
if (defined $ENV{LD_LIBRARY_PATH}) {
    $ldpath = ":" . ($ENV{LD_LIBRARY_PATH} || "");
}

$ENV{LD_LIBRARY_PATH} = "../../lib" . $ldpath;

use Test::Simple tests => 2;
use Bacon::Test;

my $tmp = "t/out-$$.dat";

system("./bmmul -k 2 -a t/aa.dat -b t/id4.dat -o $tmp");
files_eq($tmp, "t/aa.dat", "BlockMatMul - identity matrix");
unlink($tmp);

system("./bmmul -k 2 -a t/aa.dat -b t/bb.dat -o $tmp");
files_eq($tmp, "t/out.dat", "BlockMatMul - arbitrary matrix");
unlink($tmp);
