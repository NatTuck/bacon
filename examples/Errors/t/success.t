#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use FindBin qw($Bin);
chdir "$Bin/..";

use Test::More tests => 1;
use Bacon::Test;

use File::Slurp qw(slurp);

my $tmp = "t/out-$$.dat";

system("./errors t/success.dat 2>&1 > $tmp");

my $output = slurp($tmp);
is($output, '', "Execution with no errors");

unlink($tmp);
