package Bacon::OpExpr;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

has name => (is => 'ro', isa => 'Str', required => 1);
has args => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]');

sub new_args {
    my ($class, $op, @args) = @_;
    my $self = $class->new_from_token(name => $op, args => [@args]);
    return $self;
}

__PACKAGE__->meta->make_immutable;
1;
