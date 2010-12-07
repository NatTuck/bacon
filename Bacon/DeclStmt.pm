package Bacon::DeclStmt;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

has var => (is => 'rw', isa => 'Bacon::Variable', required => 1);
has val => (is => 'rw', isa => 'Maybe[Bacon::Expr]');

use Bacon::Utils;

sub new2 {
    my ($class, $var, $init) = @_;
    my $self = $class->new(
        file => $var->file, line => $var->line,
        var => $var, val => $init);
    return $self;
}

sub gen_code {
    my ($self, $depth) = @_;
    my $code = $self->var->gen_code($depth);

    if (defined $self->val) {
        $code .= " = " . $self->val->gen_code(0);    
    }

    return $code . ";\n";
}

__PACKAGE__->meta->make_immutable;
1;
