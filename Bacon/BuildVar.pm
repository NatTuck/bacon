package Bacon::BuildVar;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;
use Carp;

has type   => (is => 'rw', isa => 'Maybe[Str]');
has name   => (is => 'rw', isa => 'Maybe[Str]');
has dims   => (is => 'rw', isa => 'Maybe[ArrayRef[Bacon::Expr]]');
has init   => (is => 'rw', isa => 'Maybe[Bacon::Expr]');
has source => (is => 'ro', isa => 'Str', required => 1);

use Bacon::Utils;

sub new_from_attr_token {
    my ($class, $attr, $token) = @_;
    return $class->new(
        source => ($token->file.":".$token->line),
        $attr  => $token->text);
}

sub new_by_type {
    my ($class, $type) = @_;

    if ($type->isa('Bacon::Token')) {
        return $self->new_from_attr_token(type => $type);
    }

    if ($type->isa('Bacon::BuildVar')) {
        return $type;
    }

    confess "What makes you think a " . ref($type) . " is a type?";
}

sub new_by_name {
    my ($class, $name) = @_;
    return $class->new_from_attr_token(name => $name);
}

sub new_by_ptype {
    my ($class, $ptype, $param) = @_;
    my $tname = $ptype->text . "<" . $param->text . ">";
    return $class->new(
        source => ($ptype->file.":".$ptype->line),
        type   => $tname);
}

sub add_type {
    my ($self, $new_type) = @_;
    my $type = $self->type || '';

    if ($new_type->isa('Bacon::Token')) {
        $self->type($type . ' ' . $new_type->text);
    }

    if ($new_type->isa('Bacon::BuildVar')) {
        $self->type($type . ' ' . $new_type->type);
    }

    return $self;
}

sub decl_stmt {
    my ($self) = @_;
    confess "No name: " . Dumper($self) unless $self->name;
    confess "No type: " . Dumper($self) unless $self->type;

    confess "Array initializers not supported"
        if (defined $self->init && defined $self->dims);

    return Bacon::Stmt::VarDecl->new(
        file => $self->file, line => $self->line,
        type => $self->type, name => $self->name, 
        dims => $self->dims, init => $self->init
    );
}

sub fun_arg {
    my ($self) = @_;
    confess "No name: " . Dumper($self) unless $self->name;
    confess "No type: " . Dumper($self) unless $self->type;
    confess "Fun Args can't have dims" if $self->dims;

    return Bacon::Variable->new2($self->name, $self->type);
}

__PACKAGE__->meta->make_immutable;
1;
