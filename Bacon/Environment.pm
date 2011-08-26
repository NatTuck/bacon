package Bacon::Environment;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has parent    => (is => 'rw', isa => 'Maybe[Bacon::Environment]');
has vars      => (is => 'rw', isa => 'HashRef[Bacon::Variable]', 
                      default => sub { {} });
has in_kernel => (is => 'ro', isa => 'Bool', required => 1);


# Specs is a list of specialized functions called in this
# environment. This is generated by mutation during AST
# traversal and shared by all functions seen during an
# AST traversal generation.
#
# "fun__spec__a_b_c" => "code"
has funs      => (is => 'rw', isa => 'HashRef[Bacon::Function]',
                      default => sub { {} });
has specs     => (is => 'rw', isa => 'HashRef[Item]',
                      default => sub { {} });

use Clone qw(clone);
use Try::Tiny;
use List::MoreUtils qw(uniq);

use Bacon::Utils qw(embiggen);

sub list {
    my ($self) = @_;
    my @names = keys %{$self->vars};

    if (defined $self->parent) {
        push @names, $self->parent->list;
    }

    return uniq(@names);
}

sub spawn_child {
    my ($self) = @_;
    return Bacon::Environment->new(
        parent    => $self,
        in_kernel => $self->in_kernel,
        funs      => $self->funs,
        specs     => $self->specs);
}

sub lookup {
    my ($self, $name) = @_;

    if (defined $self->vars->{$name}) {
        return $self->vars->{$name};
    }

    if (defined $self->parent) {
        return $self->parent->lookup($name);
    }

    return undef;
}

sub value {
    my ($self, $name) = @_;
    my $value = undef;
    try {
        $value = $self->lookup($name)->value;
    };
    return $value;
}

sub add {
    my ($self, $var) = @_;
    confess "\$var not defined" unless defined $var;
    my $name = $var->name;
    $self->vars->{$name} = $var;

    for my $dim ($var->dim_vars) {
        $self->add($dim);
    }
}

sub update_with {
    my ($self, %vals) = @_;
    
    my $env = Bacon::Environment->new(
        parent => $self, in_kernel => $self->in_kernel,
        funs => $self->funs, specs => $self->specs);
    
    for my $name (keys %vals) {
        my $var = clone($self->lookup($name));
        my $vv  = embiggen($vals{$name});
        $var->value($vv);
        $env->add($var);
    }

    return $env;
}

sub dump_values {
    my ($self) = @_;
    for my $name (keys %{$self->vars}) {
        my $value = $self->vars->{$name}->value // 'undef';
        say "$name = $value";
    }
}

__PACKAGE__->meta->make_immutable;
1;
