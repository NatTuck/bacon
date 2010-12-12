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
has retv => (is => 'rw', isa => 'Maybe[Str]');
has body => (is => 'rw', isa => 'Maybe[Bacon::CodeBlock]');

# Symbol table.
has vtab => (is => 'ro', isa => 'HashRef[VarInfo]', 
        lazy => 1, builder => 'build_vtab');

use Bacon::Utils;

sub new3 {
    my ($class, $specs, $decl, $body) = @_;
    my $self = $decl->update_with($specs);
    $self->body($body);
    return $self;
}

sub kids {
    my ($self) = @_;
    return (@{$self->args}, $self->body);
}

sub return_type {
    my ($self) = @_;
    return "void" unless (defined $self->retv);
    return $self->retv;
}

sub expand_vars {
    my ($self, @vars) = @_;

    my @expanded = ();
    for my $var (@vars) {
        push @expanded, $var->expand;
    }

    return @expanded;
}

sub build_vtab {
    my ($self) = @_;
    return {};
}

sub exp_args {
    my ($self) = @_;
    my $vars = $self->vtab;

    for my $name (keys %$vars) {
        my $info = $vars->{$name};
        next unless $info->is_arg;

    }
}

sub exp_vars {
    my ($self) = @_;
}

sub to_opencl {
    my ($self, $pgm) = @_;
    assert_type($pgm, "Bacon::Program");

    my $code = "/* Function: " . $self->name . 
               " " . $self->source . " */\n";

    $code .= $self->return_type . "\n";

    my @args = $self->expand_vars(@{$self->args});
    $code .= $self->name . "(";
    $code .= join(', ', map {$_->to_opencl(0)} @args);
    $code .= ")\n";

    $code .= "{\n";
    
    my @vars = $self->expand_vars($self->find_decls);
    for my $var (@vars) {
        $code .= $var->decl_to_opencl(1);
    }

    $code .= $self->body->contents_to_opencl(0);

    $code .= "}\n\n";

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
