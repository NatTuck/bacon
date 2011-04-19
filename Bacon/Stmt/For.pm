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

our $MAX_UNROLL = 16;

use Bacon::Utils;

has init => (is => 'rw', isa => 'Bacon::Stmt');
has cond => (is => 'rw', isa => 'Bacon::Expr');
has incr => (is => 'rw', isa => 'Bacon::Expr');
has body => (is => 'rw', isa => 'Bacon::Stmt');

has unroll => (is => 'rw', isa => 'ListRef[Item]');

sub kids {
    my ($self) = @_;
    return ($self->init, $self->cond, $self->incr, $self->body);
}

sub try_unrolling {
    my ($self, $fun) = @_;

    my $var_name = undef;
    my $var_init = undef;
    my $end_cond = undef;
    my $end_numb = undef;
    my $var_incr = undef;

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

    return undef unless (defined $var_name && defined $var_init);

    if ($self->cond->isa('Bacon::Expr::BinaryOp')
            && $self->cond->is_const_cond($fun, $var_name)) {
        ($end_cond, $end_numb) = $self->cond->normalize_const_cond($fun, $var_name);
    }

    if ($self->incr->isa('Bacon::Expr')) {
        $var_incr = $self->incr->normalize_increment($fun, $var_name);
    }

    return undef unless defined $var_incr;

    for my $node ($self->body->subnodes) {
        return undef if $node->mutates_variable($var_name);
    }

    return $self->unroll_loop($fun, $var_name, $var_init, $end_numb, $var_incr, $end_cond);
}

sub unroll_loop {
    my ($self, $fun) = @_;
    $sellf->try_unrolling($fun) unless (defined $self->unroll);
    my ($var, $r0, $rN, $step, $cond) = @{$self->unroll};

    my $range = $rN - $r0; 
    my $cost  = $self->cost($fun);

    say "$var from $r0 to $cond $rN by $step; $range items; cost = $cost";

    return undef;
}

sub to_opencl {
    my ($self, $fun, $depth) = @_;

    my $unrolled = $self->try_unrolling($fun);
    return $unrolled if $unrolled;

    # Non-unrolled for loop
    my $code = indent($depth) . "for (";

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
