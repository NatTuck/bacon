package Bacon::Function;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;

use Bacon::AstNode;
extends 'Bacon::AstNode', 'Bacon::Template';
use Bacon::SymbolTable;

has name => (is => 'rw', isa => 'Str');
has args => (is => 'rw', isa => 'ArrayRef[Bacon::Variable]');
has body => (is => 'rw', isa => 'Maybe[Bacon::Stmt::Block]');
has rets => (is => 'rw', isa => 'Maybe[Bacon::Type]');

has symtab => (is => 'rw', isa => 'Bacon::SymbolTable', lazy_build => 1);


use Bacon::Utils;

sub new3 {
    my ($class, $return_type, $self, $body) = @_;
    assert_type($body, 'Bacon::Stmt::Block');
    $self->rets($return_type);
    $self->body($body);
    return $self;
}

sub kids {
    my ($self) = @_;
    return (@{$self->args}, $self->body);
}

sub _build_symtab {
    my ($self) = @_;
    my $symtab = Bacon::SymbolTable->new(function => $self);

    $symtab->add_args(@{$self->args});

    my @locals= grep { $_->isa('Bacon::Stmt::VarDecl') } $self->subnodes;
    $symtab->add_locals(@locals);

    return $symtab;
}

sub lookup_variable {
    my ($self, $name) = @_;
    return $self->symtab->lookup($name);
}

sub symtab_find_args {
    my ($self) = @_;
    return @{$self->symtab->args};
}

sub symtab_find_local_vars {
    my ($self) = @_;
    return @{$self->symtab->locals};
}

sub returns_void {
    my ($self) = @_;
    die "Undefined return type" unless (defined $self->rets);
    return $self->rets->is_void;
}

sub lookup_error_string {
    my ($self, $string) = @_;
    die "Error strings in non-kernel functions unsupported.";
}

sub var_is_const {
    my ($self, $vname) = @_;
    # No const value propagation outside of kernels.
    return 0;
}

sub to_opencl {
    my ($self, $pgm) = @_;
    assert_type($pgm, "Bacon::Program");

    my $code = "/* Function: " . $self->name . 
               " " . $self->source . " */\n";

    $code .= $self->rets->to_ocl . "\n";

    my @args = @{$self->args};

    $code .= $self->name . "(";
    $code .= join(', ', map { $_->to_fun_arg($self) } @args);
    $code .= ")\n";

    $code .= "{\n";
    
    my @vars = @{$self->symtab->locals};

    for my $var (@vars) {
        $code .= $var->decl_to_opencl($self, 1);
    }

    $code .= $self->body->contents_to_opencl($self, 1);

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
