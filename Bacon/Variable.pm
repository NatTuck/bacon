package Bacon::Variable;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Utils;

extends 'Bacon::AstNode';

has type => (is => 'rw', isa => 'Str');
has name => (is => 'rw', isa => 'Str');

sub gen_code {
    my ($self, $depth) = @_;
    return $self->indent($depth) . $self->type . " " . $self->name; 
}

sub new_by_type {
    my ($class, $type) = @_;
    assert_type($type, 'Bacon::Token');

    return $class->new(
        file => $type->file,
        line => $type->line,
        type => $type->text,
        name => "",
    );
}

sub new_by_name {
    my ($class, $name) = @_;
    assert_type($name, 'Bacon::Token');

    return $class->new(
        file => $name->file,
        line => $name->line,
        type => "",
        name => $name->text,
    );
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
