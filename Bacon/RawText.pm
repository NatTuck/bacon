package Bacon::RawText;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;
use Carp;

use Bacon::Utils;

use Bacon::Expr;
use Exporter;
extends 'Bacon::Expr', 'Exporter';

our @EXPORT = qw(mkraw);

has text => (is => 'ro', isa => 'Str');

sub mkraw {
    my ($text) = @_;
    return Bacon::RawText->new(
        file => 'none', line => 12345678, text => $text
    );
}

sub to_opencl {
    my ($self, undef, undef)  = @_;
    return $self->text;
}

__PACKAGE__->meta->make_immutable;
1;
