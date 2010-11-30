package Bacon::Program;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

extends 'Bacon::AstNode';

has constants => (is => 'rw', isa => 'ArrayRef[Bacon::Variable]',
                  default => sub { [] });
has functions => (is => 'rw', isa => 'ArrayRef[Bacon::Function]',
                  default => sub { [] });

use Bacon::Utils;

sub add_constant {
    my ($self, $const) = @_;
    assert_type($const, 'Bacon::Variable');
    push @{$self->constants}, $const;
}

sub add_function {
    my ($self, $fun) = @_;
    assert_type($fun, 'Bacon::Function');
    push @{$self->functions}, $fun;
}

sub gen_code {
    my ($self) = @_;

    my $code = "/* Bacon::Program: " . $self->source . " */\n\n";

    for my $var (@{$self->constants}) {
        $code .= $var->gen_code;
    }

    for my $fun (@{$self->functions}) {
        $code .= $fun->gen_code;
    }

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
