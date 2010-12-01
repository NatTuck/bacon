package Bacon::Stmt;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::AstNode;
extends 'Bacon::AstNode';

use Bacon::Utils;

sub gen_code {
    my (undef, $depth) = @_;
    return indent($depth) . "/* pass */ ;\n";
}

__PACKAGE__->meta->make_immutable;
1;
