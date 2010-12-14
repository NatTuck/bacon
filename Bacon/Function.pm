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
has body => (is => 'rw', isa => 'Maybe[Bacon::CodeBlock]');

# Symbol table.
has vtab => (is => 'rw', isa => 'Maybe[Item]',
        lazy => 1, builder => 'build_vtab');

use Bacon::Utils;

sub new3 {
    my ($class, $specs, $decl, $body) = @_;
    assert_type($body, 'Bacon::CodeBlock');
    my $self = $decl->update_with($specs);
    $self->body($body);
    return $self;
}

sub kids {
    my ($self) = @_;
    assert_type($self->body, "Bacon::CodeBlock");
    return (@{$self->args}, $self->body);
}

sub build_vtab {
    my ($self) = @_;
    my $vtab = {};

    for my $var (@{$self->args}, $self->find_decls) {
        my $name = $var->name;
        confess "Duplicate variable '$name'" if (defined $vtab->{$name});
        $vtab->{$name} = $var;
    }

    assert_type($_, 'Bacon::Variable') for (values %{$vtab});
    die "Function has no variables?" if (scalar keys %$vtab == 0);
    return $vtab;
}

sub find_decls {
    my ($self) = @_;
    return grep { $_->isa('Bacon::DeclStmt') } $self->subnodes;
}

sub expanded_args {
    my ($self) = @_;
    my @unexp = grep { $_->isa('Bacon::FunArg') } values %{$self->vtab};
    my @args = ();
    for my $arg (@unexp) {
        push @args, $arg->expand;
    }
    return @args;
}

sub expanded_vars {
    my ($self) = @_;
    my @unexp = grep { !$_->isa('Bacon::FunArg') } values %{$self->vtab};
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

__PACKAGE__->meta->make_immutable;
1;
