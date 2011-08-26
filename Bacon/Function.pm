package Bacon::Function;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;

use Bacon::AstNode;
use Bacon::Template;
extends 'Bacon::AstNode', 'Bacon::Template';

has name => (is => 'ro', isa => 'Str', required => 1);
has args => (is => 'ro', isa => 'ArrayRef[Bacon::Variable]', required => 1);
has body => (is => 'ro', isa => 'Bacon::Stmt::Block', required => 1);
has rets => (is => 'ro', isa => 'Bacon::Type', required => 1);

has env =>  (is => 'ro', isa => 'Bacon::Environment', lazy_build => 1);

use List::MoreUtils qw(any);

use Bacon::Utils;
use Bacon::Environment;

sub _build_env {
    my ($self) = @_;
    my $in_kernel = $self->isa('Bacon::Kernel');

    my $env = Bacon::Environment->new(in_kernel => $in_kernel);

    for my $arg (@{$self->args}) {
        $env->add($arg);
    }

    my @decls = grep { $_->isa('Bacon::Stmt::VarDecl') } $self->subnodes;

    for my $decl (@decls) {
        die Dumper($decl) unless defined $decl->var;
        $env->add($decl->var);
    }

    return $env;
}

sub const_args {
    my ($self) = @_;
    my @cargs = ();

    my @args = @{$self->args};

    for my $arg (@args) {
        my $var = $self->env->lookup($arg->name);

        if ($var->is_const) {
            push @cargs, $var->name;
        }
        elsif ($var->has_dims) {
            for my $dim (@{$var->type->dims}) {
                push @cargs, $var->name . '.' . $dim;
            }
        }
    }

    return @cargs;
}

sub kids {
    my ($self) = @_;
    return (@{$self->args}, $self->body);
}

sub returns_void {
    my ($self) = @_;
    die "Undefined return type" unless (defined $self->rets);
    return $self->rets->is_void;
}

sub local_decls {
    my ($self) = @_;
    return grep { $_->isa('Bacon::Stmt::VarDecl') } $self->subnodes;
}

sub deduce_image_modes {
    my ($self, $env) = @_;

    for my $name ($env->list) {
        my $var = $env->lookup($name);
        next unless $var->type_isa("Bacon::Type::Image");

        my @nodes = $self->subnodes;
        if (any { $_->isa("Bacon::Expr::BinaryOp") && $_->writes_to_array($name) } @nodes) {
            $var->type->mode("wo");
        }
        else {
            $var->type->mode("ro");
        }
    }

}

sub eval_const_vars {
    my ($self, $env) = @_;
    
    my @decls = $self->local_decls;

    my @const_vars = ();
    for my $decl (@decls) {
        my $var  = $env->lookup($decl->name);
        my $name = $var->name;
        
        if ($var->has_dims) {
            my @dim_ns = @{$var->type->dims};
            my @dim_vs = @{$decl->dims};
            
            for (my $ii = 0; $ii < scalar @dim_ns; ++$ii) {
                my $nn = $dim_ns[$ii];
                my $vv = $dim_vs[$ii]->static_eval($env);
                $env->lookup("$name.$nn")->value(embiggen($vv));
            }
        }
        elsif ($var->is_const) {
            my $value = int($decl->init->static_eval($env));
            $var->value(embiggen($value));
        }
    }
}

sub to_spec_opencl {
    my ($self, $pgm) = @_;
    assert_type($pgm, "Bacon::Program");

    $self->deduce_image_modes($self->env);
    $self->eval_const_vars($self->env);
}

sub to_opencl {
    my ($self, $pgm) = @_;
    assert_type($pgm, "Bacon::Program");

    $self->deduce_image_modes($self->env);
    $self->eval_const_vars($self->env);

    my $code = "/* Function: " . $self->name . 
               " " . $self->source . " */\n";

    $code .= $self->rets->to_ocl . "\n";

    my @args = @{$self->args};

    $code .= $self->name . "(";
    $code .= join(', ', map { $_->to_fun_arg($self) } @args);
    $code .= ")\n";

    $code .= "{\n";
    
    my @vars = $self->local_decls;

    for my $var (@vars) {
        $code .= $var->decl_to_opencl($self->env, 1);
    }

    $code .= $self->body->contents_to_opencl($self->env, 1);

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
