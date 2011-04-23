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

use Clone qw(clone);
use Try::Tiny;

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
        parent => $self, in_kernel => $self->in_kernel);
    
    for my $name (keys %vals) {
        my $var = clone($self->lookup($name));
        $var->value($vals{$name});
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
