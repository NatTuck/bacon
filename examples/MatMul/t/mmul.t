#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use FindBin qw($Bin);
chdir "$Bin/..";

use Test::Simple tests => 2;
use Bacon::Test;

my $tmp = "t/out-$$.dat";

system("./mmul -a t/aa.dat -b t/id4.dat -o $tmp");
files_eq($tmp, "t/aa.dat", "MatMul - identity matrix");
unlink($tmp);

system("./mmul -a t/aa.dat -b t/bb.dat -o $tmp");
files_eq($tmp, "t/out.dat", "MatMul - arbitrary matrix");
unlink($tmp);