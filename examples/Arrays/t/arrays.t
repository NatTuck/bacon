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

use Test::Simple tests => 1;
use Bacon::Test;

my $tmp = "t/out-$$.dat";

system("./arrays -f -x 4 -y 2 > $tmp");
files_eq($tmp, "t/rect2x4.out", "Non-square 2d array.");
unlink($tmp);

