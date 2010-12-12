package Bacon::Program;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

extends 'Bacon::AstNode';

has constants => (is => 'rw', isa => 'ArrayRef[Bacon::DeclStmt]',
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

sub to_opencl {
    my ($self) = @_;

    my $code = "/* Bacon::Program: " . $self->source . " */\n\n";

    for my $var (@{$self->constants}) {
        die "Global constants not yet supported"
        #$code .= $var->to_opencl(0);
    }

    for my $fun (@{$self->functions}) {
        $code .= $fun->to_opencl($self);
    }

    return $code;
}

sub to_wrapper_cc {
    my ($self) = @_;
    my $header = $self->basefn . ".hh";
    my $code = "/* C++ wrapper implementation */\n";
    $code .= qq{#include "$header"\n};
    return $code;
}

sub to_wrapper_hh {
    my ($self) = @_;
    my $guard = "BACON_" . uc($self->basefn) . "_HH_GUARD";
    my $code = "";
    $code .= "#ifndef $guard\n";
    $code .= "#define $guard\n";
    $code .= "\n\n";
    $code .= "#endif\n";
    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
