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

system("./add -a t/aa.dat -b t/bb.dat -o $tmp");
files_eq($tmp, "t/out.dat", "Array2D add");
unlink($tmp);

system("./add -d -o $tmp");
files_eq($tmp, "t/dub.dat", "Array2D add");
unlink($tmp);
