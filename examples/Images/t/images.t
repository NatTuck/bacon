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

my $tmp = "t/out-$$.dat";

system("./images -i -y 4 -x 4 > $tmp");
files_eq($tmp, "t/out4x4.txt", "Write to Image2D.");
unlink($tmp);

system("./images -t < t/rect2x4.dat > $tmp");
files_eq($tmp, "t/rect2x4.dat", "Read Image2D into Array2D.");
unlink($tmp);

system("./images -a < t/long3x7.dat > $tmp");
files_eq($tmp, "t/long3x7out.dat", "Long int in Image2D.");
unlink($tmp);

SKIP: {
    skip "Image3D writes are janky", 1;

    system("./images -3 > $tmp");
    files_eq($tmp, "t/i3d_sums.out", "Write and then read Image3D.");
    unlink($tmp);
}
