package Bacon::Test;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(files_eq);

use Test::More;
use File::Slurp qw(slurp);

sub files_eq {
    my ($aa, $bb, $test) = @_;
    my $aa_text = slurp($aa);
    $aa_text =~ s/\s+/ /g;
    my $bb_text = slurp($bb);
    $bb_text =~ s/\s+/ /g;
    is($aa_text, $bb_text, $test);
}

1;
