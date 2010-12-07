package Bacon::Variable;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;
use Carp;

use Bacon::Utils;

use Bacon::Expr;
use Bacon::Stmt;
extends 'Bacon::Expr', 'Bacon::Stmt';

has type => (is => 'rw', isa => 'Str', default => "");
has name => (is => 'rw', isa => 'Maybe[Str]');
has init => (is => 'rw', isa => 'Maybe[Bacon::Expr]');
has dims => (is => 'rw', isa => 'Maybe[ArrayRef[Bacon::Expr]]');


sub new_by_type {
    my ($class, $type) = @_;

    if ($type->isa('Bacon::Token')) {
        return $class->new_from_token(
            undef => $type, type => $type->text);
    }

    if ($type->isa('Bacon::Variable')) {
        return $class->new_from_node($type);
    }

    confess "What makes you think a " . ref($type) . " is a type?";
}

sub new_by_name {
    my ($class, $name) = @_;
    return $class->new_from_token(name => $name);
}

sub new_ptype {
    my ($class, $ptype, $param) = @_;
    my $tname = $ptype->text . "<" . $param->text . ">";
    return $class->new_from_token(undef => $ptype, type => $tname);
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

sub gen_code {
    my ($self, $depth) = @_;
    confess "no name" unless $self->name;
    my $code = indent($depth);

    if ($self->type) {
        $code .= $self->type . " ";
    }

    $code .= $self->name;

    if (defined $self->dims) {
        my @dc = map { $_->gen_code(0) } @{$self->dims};
        $code .= "[ " . join(", ", @dc) . "]";
    }

    if (defined $self->init) {
        $code .= " = " . $self->init->gen_code(0);
    }

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
