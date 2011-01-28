package Bacon::Type::Array;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Carp;

sub index {
    my ($self, $fun, $idx, @extra) = @_;
    croak "Invalid multiple index for Array" if (scalar @extra != 0);
    return $idx->to_opencl($fun, 0);
}

__PACKAGE__->meta->make_immutable;
1;
