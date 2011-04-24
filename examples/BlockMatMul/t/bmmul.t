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

use Test::More tests => 5;
use Bacon::Test;

my $tmp = "t/out-$$.dat";

system("./bmmul -k 2 -a t/aa.dat -b t/id4.dat -o $tmp");
files_eq($tmp, "t/aa.dat", "BlockMatMul - identity matrix");
unlink($tmp);

system("./bmmul -k 2 -a t/aa.dat -b t/bb.dat -o $tmp");
files_eq($tmp, "t/out.dat", "BlockMatMul - arbitrary matrix");
unlink($tmp);

system("./bmmul -p -k 2 -a t/aa.dat -b t/id4.dat -o $tmp");
files_eq($tmp, "t/aa.dat", "BlockMatMul - private mem identity matrix");
unlink($tmp);

system("./bmmul -p -k 2 -a t/aa.dat -b t/bb.dat -o $tmp");
files_eq($tmp, "t/out.dat", "BlockMatMul - private mem arbitrary matrix");
unlink($tmp);

my $result  = `./bmmul -p -k 2 -c -n 512`;
my $correct = <<"EOF";
Random test of 512x512 matrices at block size = 2
Random test succeeded.
EOF
ok($result eq $correct, "BlockMatMul - private block large matrix");

