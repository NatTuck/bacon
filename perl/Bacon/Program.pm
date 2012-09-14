package Bacon::Program;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::AstNode;
use Bacon::Template;
extends 'Bacon::AstNode', 'Bacon::Template';

has constants => (is => 'rw', isa => 'ArrayRef[Bacon::DeclStmt]',
                  default => sub { [] });
has functions => (is => 'rw', isa => 'ArrayRef[Bacon::Function]',
                  default => sub { [] });

use Data::Dumper;
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

sub kids {
    my ($self) = @_;
    return @{$self->functions};
}

sub kernels {
    my ($self) = @_;
    return grep { $_->isa('Bacon::Kernel') } @{$self->functions};
}

sub get_kernel {
    my ($self, $name) = @_;

    for my $kern ($self->kernels) {
        return $kern if ($kern->name eq $name);
    }

    die "No such kernel: $name";
}

sub non_kernel_functions {
    my ($self) = @_;
    return grep { !$_->isa('Bacon::Kernel') } @{$self->functions};
}

sub to_spec_opencl {
    my ($self, $kern_name, @const_args) = @_;
    my $code = '';

    for my $var (@{$self->constants}) {
        die "Global constants not yet supported";
        #$code .= $var->to_opencl(0);
    }

    # First generate code for specialized kernel.
    my $kernel = $self->get_kernel($kern_name);
    $code .= $kernel->to_spec_opencl($self, @const_args);

    return $self->fill_section(
        spec_opencl => 0,
        source      => $self->source,
        kern_name   => $kern_name,
        show_args   => "@const_args",
        contents    => $code);
}

sub to_wrapper_cc {
    my ($self) = @_;
    my $code = '';

    for my $fun ($self->kernels) {
        $code .= $fun->to_wrapper_cc($self);
    }

    return $self->fill_section(
        wrapper_cc => 0,
        contents   => $code);
}

sub to_wrapper_hh {
    my ($self) = @_;
    my $code = '';

    for my $fun ($self->kernels) {
        $code .= $fun->to_wrapper_hh($self);
    }
    
    return $self->fill_section(
        wrapper_hh => 0,
        contents   => $code);
}

__PACKAGE__->meta->make_immutable;
1;

__DATA__
<<"END_OF_DATA";

__[ spec_opencl ]__

/* Bacon::Program: <% $source %> */
/* specialized <% $kern_name %> on <% $show_args %> */

#include <Bacon/Array.cl>
#include <Bacon/Image.cl>

<% $contents %>

/* vim: ft=c
 */

__[ wrapper_cc ]__

/* Generated Methods */

<% $contents %>


__[ wrapper_hh ]__

/* Generated prototypes */

<% $contents %>


__[ EOF ]__
END_OF_DATA
