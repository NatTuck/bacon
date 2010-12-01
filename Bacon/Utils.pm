package Bacon::Utils;
use warnings FATAL => 'all';
use strict;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(indent assert_type);

use Carp;
use Try::Tiny;

sub indent {
    my ($depth) = @_;
    return "    " x $depth;
}

sub assert_type {
    my ($obj, $expect_type) = @_;

    try {
        unless ($obj->isa($expect_type)) {
            my $actual_type = ref($obj);
            confess("Got type '$actual_type' instead of '$expect_type'");
        }
    } catch {
        confess("Exception: $_");
    };
}

1;
