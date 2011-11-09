package Bacon::Stmt;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;

use Bacon::AstNode;
extends 'Bacon::AstNode';

use Bacon::Utils;

sub to_opencl {
    my ($self, $env, $depth) = @_;
    return indent($depth) . "/* pass */ ;\n";
}

__PACKAGE__->meta->make_immutable;
1;
