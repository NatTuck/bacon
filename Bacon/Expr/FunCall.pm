package Bacon::Expr::FunCall;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

use Bacon::Utils;

has name => (is => 'ro', isa => 'Str', required => 1);
has args => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]', required => 1);

sub new_args {
    my ($class, $op, @args) = @_;
    return $class->new_from_token(name => $op, args => [@args]);
}

sub kids {
    my ($self) = @_;
    return @{$self->args};
}

sub to_opencl {
    my ($self, $fun, $depth) = @_;

    if ($self->name eq 'fail') {
        my $string = $self->args[0];
        my $err_no = $fun->lookup_string($string);

        my $code = indent($depth) . "__bacon__fail = $err_no;\n"

        if (scalar @{$self->args} > 1) {

        }
            
    }

    my @args = @{$self->args};
    my @ac   = map { $_->to_opencl($fun, 0) } @args;
    return indent($depth) 
        . $self->name 
        . '(' 
        . join(', ', @ac) 
        . ')';
}

__PACKAGE__->meta->make_immutable;
1;
