package Bacon::CodeBlock;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has vars => (is => 'rw', isa => 'ArrayRef[Bacon::Variable]',
    default => sub { [] });
has code => (is => 'rw', isa => 'ArrayRef[Bacon::Stmt]',
    default => sub { [] });

sub gen_code {
    my ($self, $depth) = @_;
    my $code = indent($depth) . "{\n";

    for my $var (@{$self->vars}) {
        $code .= $var->gen_code($depth + 1). ";\n";
    }
    
    for my $smt (@{$self->code}) {
        $code .= $smt->gen_code($depth + 1);
    }

    $code .= indent($depth) . "}\n";
    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
