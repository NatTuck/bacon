package Bacon::Stmt::For;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;
use Try::Tiny;

use Bacon::Stmt;
use Bacon::Template;
extends 'Bacon::Stmt', 'Bacon::Template';

our $MAX_UNROLL_SIZE = 16;
our $MAX_UNROLL_COST = 1000;

use Bacon::Utils;

has init => (is => 'ro', isa => 'Bacon::Stmt', required => 1);
has cond => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has incr => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has body => (is => 'ro', isa => 'Bacon::Stmt', required => 1);

has can_unroll  => (is => 'rw', isa => 'Maybe[Bool]');
has unroll_info => (is => 'rw', isa => 'Maybe[Item]');

sub kids {
    my ($self) = @_;
    return ($self->init, $self->cond, $self->incr, $self->body);
}

sub build_unroll_info {
    my ($self, $env) = @_;
    return if (defined $self->can_unroll);

    my $var_name = undef;
    my $var_init = undef;
    my $end_cond = undef;
    my $end_numb = undef;
    my $var_incr = undef;

    if ($self->init->isa('Bacon::Stmt::VarDecl')) {
        $var_name = $self->init->name;
        $var_init = $self->init->init->try_static_eval($env);
    }
    
    if ($self->init->isa('Bacon::Stmt::Expr')) {
        my $init = $self->init->expr;

        if ($init->isa('Bacon::Expr::BinaryOp') 
                && $init->name eq '='
                && $init->arg0->isa('Bacon::Expr::Identifier')) {       
            $var_name = $init->arg0->name;
            $var_init = $init->arg1->try_static_eval($env);
        }
    }

    unless (defined $var_name && defined $var_init) {
        $self->can_unroll(0);
        return;
    }

    if ($self->cond->isa('Bacon::Expr::BinaryOp')
            && $self->cond->is_const_cond($env, $var_name)) {
        ($end_cond, $end_numb) = $self->cond->normalize_const_cond($env, $var_name);
    }

    if ($self->incr->isa('Bacon::Expr')) {
        $var_incr = $self->incr->normalize_increment($env, $var_name);
    }

    unless (defined $var_incr) {
        $self->can_unroll(0);
        return;
    }

    if ($self->body->mutates_variable($var_name)) {
        $self->can_unroll(0);
        return;
    }

    $self->can_unroll(1);
    $self->unroll_info(
        [$var_name, $var_init, $end_numb, $var_incr, $end_cond]);
}

sub unroll {
    my ($self, $env) = @_;
    return unless $self->can_unroll;
    my ($var, $r0, $rN, $incr, $cond) = @{$self->unroll_info};
    my $range = $rN - $r0;
    my $cost  = $self->cost($env);

    return "$var [$r0 .. $rN] by $incr; $range items, $cost";
}

sub to_opencl {
    my ($self, $env, $depth) = @_;
    $self->build_unroll_info($env);

    if ($self->can_unroll) {
        #say $self->unroll($env);
    }

    my $init = $self->init->to_opencl($env, 0);
    $init =~ s/;$//;
    chomp $init;

    return $self->fill_section(
        opencl_code => $depth,
        init => $init,
        cond => $self->cond->to_ocl($env),
        incr => $self->incr->to_ocl($env),
        body => $self->body->contents_to_opencl($env, $depth));
}

__PACKAGE__->meta->make_immutable;
1;

__DATA__
<<"END_OF_DATA";

__[ opencl_code ]__

for (<% $init %>; <% $cond %>; <% $incr %>) {
    <% $body %>
}

__[ EOF ]__
END_OF_DATA
