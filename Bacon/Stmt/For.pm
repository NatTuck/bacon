package Bacon::Stmt::For;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;
use Try::Tiny;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has init => (is => 'rw', isa => 'Bacon::Stmt');
has cond => (is => 'rw', isa => 'Bacon::Expr');
has incr => (is => 'rw', isa => 'Bacon::Expr');
has body => (is => 'rw', isa => 'Bacon::Stmt');

sub kids {
    my ($self) = @_;
    return ($self->init, $self->cond, $self->incr, $self->body);
}

sub try_unrolling {
    my ($self, $fun) = @_;

    my $var_name;
    my $var_init;
    my $end_cond;
    my $var_incr;

    if ($self->init->isa('Bacon::Stmt::VarDecl')) {
        $var_name = $self->init->name;
        $var_init = $self->init->init->try_static_eval($fun);
    }
    
    if ($self->init->isa('Bacon::Stmt::Expr')) {
        my $init = $self->init->expr;

        if ($init->isa('Bacon::Expr::BinaryOp') 
                && $init->name eq '='
                && $init->arg0->isa('Bacon::Expr::Identifier')) {       
            $var_name = $init->arg0->name;
            $var_init = $init->arg1->try_static_eval($fun);
        }
    }

    return 0 unless $var_name && $var_init;

    say "$var_name = $var_init";

    if ($self->cond->isa('Bacon::Expr::BinaryOp')
            && $self->cond->is_const_cond($var_name)) {
        //////// FIXME
    }


    return (1, $var_name, $var_init, $end_cond, $var_incr);
}

sub can_unroll {
    my ($self, $fun) = @_;
    return $self->loop_var($fun);
}

sub to_opencl {
    my ($self, $fun, $depth) = @_;
    my $code = indent($depth) . "for (";

    my @unroll = $self->try_unrolling($fun);

    if ($unroll[0]) {
        die "Unroll succeeded";
    }


    if (defined $self->init) {
        $code .= $self->init->to_opencl($fun, 0);
        chomp($code);
        $code =~ s/;$//;
        $code .= "; ";
    }
    else {
        $code .= "; ";
    }

    if (defined $self->cond) {
        $code .= $self->cond->to_ocl($fun);
    }
    $code .= "; ";

    if (defined $self->incr) {
        $code .= $self->incr->to_ocl($fun);
    }
    $code .= ")\n";

    $code .= $self->body->to_opencl($fun, $depth + 1);

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
