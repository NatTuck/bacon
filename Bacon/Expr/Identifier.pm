package Bacon::Expr::Identifier;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;
use Carp;

use Bacon::Utils;
use Bacon::MagicVars;

use Bacon::Expr;
extends 'Bacon::Expr';

has name => (is => 'ro', isa => 'Str');

sub to_ocl {
    my ($self, $fun) = @_;
    confess "Undefined \$fun" unless defined $fun;

    my $name = $self->name;

    # Handle "magic" variables.
    if ($name =~ /^\$/) {
        confess "Invalid magic variable: $name"
            unless Bacon::MagicVars::magic_var_exists($name);
        $name =~ s/^\$/_bacon__S/;
        return $name;
    }

    if ($fun->var_is_const($name)) {
        return $self->static_eval($fun);
    }
    
    return $name;
}

sub to_cpp {
    my ($self, undef) = @_;
    my $name = $self->name;
    confess "Can't use magic variables in C++" if ($name =~ /^\$/);
    return $name;
}

sub static_eval {
    my ($self, $fun) = @_;
    confess "Undefined \$fun" unless defined $fun;
    return $fun->get_const($self->name);
}

__PACKAGE__->meta->make_immutable;
1;
