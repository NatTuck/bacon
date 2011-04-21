package Bacon::Stmt::Raw;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

has code => (is => 'ro', isa => 'Str', required => 1);

use Bacon::Utils;

sub to_opencl {
    my ($self, $fun, $depth) = @_;
    return indent($depth) . $self->code . ";\n";    
}

__PACKAGE__->meta->make_immutable;
1;
