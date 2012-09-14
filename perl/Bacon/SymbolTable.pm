package Bacon::SymbolTable;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has function => (is => 'rw', isa => 'Bacon::Function', required => 1);
has table    => (is => 'rw', isa => 'HashRef[Bacon::Variable]', default => sub { {} } );
has args     => (is => 'rw', isa => 'ArrayRef[Bacon::Variable]', default => sub { [] } );
has locals   => (is => 'rw', isa => 'ArrayRef[Bacon::Variable]', default => sub { [] } );
has outers   => (is => 'rw', isa => 'ArrayRef[Bacon::Variable]', default => sub { [] } );

sub lookup {
    my ($self, $name) = @_;
    confess "No variable $name in function " . $self->function->name
        unless defined $self->table->{$name};
    return $self->table->{$name}
}

sub add_var {
    my ($self, $var) = @_;
    my $name = $var->name;
    
    if (defined $self->table->{$name}) {
        die "Duplicate variable: $name in function " . $self->function->name;
    }

    $self->table->{$name} = $var;
}

sub add_args {
    my ($self, @vars) = @_;

    for my $var (@vars) {
        $self->add_var($var);
        push @{$self->args}, $var;
    }
}

sub add_locals {
    my ($self, @vars) = @_;

    for my $var (@vars) {
        $self->add_var($var);
        push @{$self->locals}, $var;
    }
}

sub add_outers {
    my ($self, @vars) = @_;

    for my $var (@vars) {
        $self->add_var($var);
        push @{$self->outers}, $var;
    }
}

sub possible_return_vars {
    my ($self) = @_;
    my $rtype = $self->function->rets;
    return grep { 
        $_->type->is_returnable && $_->type->to_cpp eq $rtype->to_cpp 
    } @{$self->outers};
}

__PACKAGE__->meta->make_immutable;
1;
