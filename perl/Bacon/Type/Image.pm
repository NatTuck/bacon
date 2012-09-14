package Bacon::Type::Image;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Type::Array;
extends 'Bacon::Type::Array';

has 'mode'  => (is => 'rw', isa => 'Str');

sub to_ocl {
    my ($self) = @_;
    confess "There's no such thing as a Bacon::Image";
}

__PACKAGE__->meta->make_immutable;
1;
