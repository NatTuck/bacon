package Bacon::Utils;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(indent assert_type in_list cpp_type cpp_header_type 
                 name_to_cc greatest_factor_not_above embiggen);

use Carp;
use Try::Tiny;
use Scalar::Util qw(blessed);

use Math::BigInt;
use Math::BigFloat;

sub indent {
    my ($depth) = @_;
    try {
        return "    " x $depth;
    }
    catch {
        confess $_;
    };
}

sub assert_type {
    my ($obj, $expect_type) = @_;

    confess("Got undef instead of '$expect_type'")
        unless (defined $obj);

    confess("Got non-object instead of '$expect_type")
        unless (ref $obj);

    try {
        unless (blessed($obj) && $obj->isa($expect_type)) {
            my $actual_type = ref($obj);
            confess("Got type '$actual_type' instead of '$expect_type'");
        }
    } catch {
        confess("Exception: $_");
    };
}

sub in_list {
    my ($item, @list) = @_;
    for my $xx (@list) {
        return 1 if $item eq $xx;
    }
    return 0;
}

sub name_to_cc {
    my ($name) = @_;
    if ($name =~ /__/) {
        $name =~ s/__/./;
        $name =~ s/$/()/;
    }
    return $name;
}

sub greatest_factor_not_above {
    my ($nn, $top) = @_;
    my $answer = 1;

    my $bound = $nn;
    $bound = $top if $bound > $top;

    for (my $ii = 2; $ii <= $bound; ++$ii) {
        if ($nn % $ii == 0) {
            $answer = $ii;
        }
    }

    return $answer;
}

sub embiggen {
    my ($number) = @_;

    confess ("Number undefined")
        unless (defined $number);

    my $text = "$number";
    if ($text =~ /\./ || $text =~ /e/i) {
        $text =~ s/f$//i;
        return Math::BigFloat->new($text);
    }
    else {
        return Math::BigInt->new($text);
    }
}

1;
