#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use FindBin qw($Bin);
chdir $Bin;

use Test::Simple tests => 1;

sub text_eq {
    my ($a_fn, $b_fn, $name) = @_;
    my $aa = `cat $a_fn`;
    my $bb = `cat $b_fn`;
    
    $aa =~ s/\s+/ /g;
    $bb =~ s/\s+/ /g;

    ok($aa eq $bb, $name);
}

my $tmp = "/tmp/out.$$";

system("./add > $tmp");
text_eq($tmp, "output.dat", "Yay!");


