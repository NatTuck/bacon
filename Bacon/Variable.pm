package Bacon::Variable;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Utils;

use Bacon::Expr;
extends 'Bacon::Expr';

has type => (is => 'rw', isa => 'Str', default => "");
has name => (is => 'rw', isa => 'Str', default => "");
has init => (is => 'rw', isa => 'Bacon::Expr');

sub gen_code {
    my ($self, $depth) = @_;
    return $self->indent($depth) . $self->type . " " . $self->name; 
}

sub new_by_type {
    my ($class, $type) = @_;
    return $class->new_from_token(type => $type);
}

sub new_by_name {
    my ($class, $name) = @_;
    return $class->new_from_token(name => $name);
}

sub add_type {
    my ($self, $new_type) = @_;
    assert_type($new_type, 'Bacon::Token');

    my %types = ();
    $types{$new_type} = 1;
   
    for my $type (split /\s+/, $self->type) {
        $types{$type} = 1;
    }

    $self->type(join(' ', keys %types));
    return $self;
}

__PACKAGE__->meta->make_immutable;
1;
