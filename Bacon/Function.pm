package Bacon::Function;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;

use Bacon::AstNode;
extends 'Bacon::AstNode';

has name => (is => 'rw', isa => 'Str');
has args => (is => 'rw', isa => 'ArrayRef[Bacon::FunArg]');
has retv => (is => 'rw', isa => 'Str', default => 'void');
has body => (is => 'rw', isa => 'Maybe[Bacon::Stmt::Block]');

# Symbol table.
has vtab => (is => 'rw', isa => 'Maybe[Item]',
        lazy => 1, builder => 'build_vtab');

# Error table.
has etab => (is => 'rw', isa => 'Item', default => sub { {} });
has enum => (is => 'rw', isa => 'Int',  default => 1);

use Bacon::Utils;

sub new3 {
    my ($class, $specs, $self, $body) = @_;
    assert_type($body, 'Bacon::Stmt::Block');
    $self->retv($specs->type);
    $self->body($body);
    return $self;
}

sub kids {
    my ($self) = @_;
    return (@{$self->args}, $self->body);
}

sub build_vtab {
    my ($self) = @_;
    my $vtab = {};

    my @decls = grep { $_->isa('Bacon::Stmt::VarDecl') } $self->subnodes;

    for my $var (@{$self->args}, @decls) {
        my $name = $var->name;
        confess "Duplicate variable '$name'" if (defined $vtab->{$name});
        $vtab->{$name} = $var;
    }

    die "Function has no variables?" if (scalar keys %$vtab == 0);
    return $vtab;
}

sub lookup_error_string {
    my ($self, $string) = @_;
    die "Error strings in non-kernel functions unsupported.";
}

sub expanded_args {
    my ($self) = @_;
    my @unexp = grep { $_->isa('Bacon::FunArg') || $_->retv } 
        values %{$self->vtab};
    my @args = ();
    for my $arg (@unexp) {
        unless ($arg->isa('Bacon::FunArg')) {
            $arg = $arg->to_funarg;
        }
        push @args, $arg->expand;
    }
    return @args;
}

sub expanded_vars {
    my ($self) = @_;
    my @unexp = grep { !$_->isa('Bacon::FunArg') && !$_->retv } 
        values %{$self->vtab};
    my @vars = ();
    for my $var (@unexp) {
        push @vars, $var->expand;
    }
    return @vars;
}

sub to_opencl {
    my ($self, $pgm) = @_;
    assert_type($pgm, "Bacon::Program");

    my $code = "/* Function: " . $self->name . 
               " " . $self->source . " */\n";

    $code .= $self->retv . "\n";

    my @args = $self->expanded_args;
    $code .= $self->name . "(";
    $code .= join(', ', map { $_->to_opencl($self, 0) } @args);
    $code .= ")\n";

    $code .= "{\n";
    
    my @vars = $self->expanded_vars;
    for my $var (@vars) {
        $code .= $var->to_opencl($self, 0) . ";\n";
    }

    $code .= $self->body->contents_to_opencl($self, 0);

    $code .= "}\n\n";

    return $code;
}

sub to_wrapper_hh {
    my ($self, $pgm) = @_;
    confess "Non-kernel functions don't produce C++ code.";
}

sub to_wrapper_cc {
    my ($self, $pgm) = @_;
    confess "Non-kernel functions don't produce C++ code.";
}

__PACKAGE__->meta->make_immutable;
1;
