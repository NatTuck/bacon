#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use FindBin qw($Bin);
chdir "$Bin/..";

use Test::More tests => 4;
use Bacon::Test;

use File::Slurp qw(slurp);

my $tmp = "t/out-$$.dat";

system("./errors t/assert_error.dat 2> $tmp");

my $output = slurp($tmp);
like($output, qr/^terminate called/, "Assert: throw exception");
like($output, qr/Bacon::Error/, "Assert: is Bacon::Error");
like($output, qr/Value should be non-negative/, "Assert: correct message");
like($output, qr/data = -4/, "Assert: correct data");

unlink($tmp);