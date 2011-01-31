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

use Test::More tests => 4;
use Bacon::Test;

use File::Slurp qw(slurp);

my $tmp = "t/out-$$.dat";

system("./errors t/fail_error.dat 2> $tmp");

my $output = slurp($tmp);
like($output, qr/^terminate called/, "Assert: throw exception");
like($output, qr/Bacon::Error/, "Assert: is Bacon::Error");
like($output, qr/Value was greater than 10/, "Assert: correct message");
like($output, qr/data = 11/, "Assert: correct data");

unlink($tmp);
