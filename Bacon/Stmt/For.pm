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

our $MAX_UNROLL_SIZE = 2;
our $MAX_UNROLL_COST = 10e9;
#our $MAX_UNROLL_COST = 0;

has init => (is => 'ro', isa => 'Bacon::Stmt', required => 1);
has cond => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has incr => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has body => (is => 'ro', isa => 'Bacon::Stmt', required => 1);

has can_unroll  => (is => 'rw', isa => 'Maybe[Bool]');
has unroll_info => (is => 'rw', isa => 'Maybe[Item]');

use Clone qw(clone);

use Bacon::Utils;
use Bacon::Expr::BinaryOp qw(mkop);
use Bacon::Expr::Literal qw(mklit);

sub kids {
    my ($self) = @_;
    return ($self->init, $self->cond, $self->incr, $self->body);
}

sub cost {
    my ($self, $env) = @_;
    $self->build_unroll_info($env);

    unless ($self->can_unroll) {
        return +'inf';
    }

    my ($var, $r0, $rN, $range, $incr, $cond) = @{$self->unroll_info};

    return $range * $self->body->cost($env);
}

sub build_unroll_info {
    my ($self, $env) = @_;
    return if (defined $self->can_unroll);

    my $var  = undef;
    my $r0   = undef;
    my $cond = undef;
    my $rN   = undef;
    my $incr = undef;

    if ($self->init->isa('Bacon::Stmt::VarDecl')) {
        $var = $self->init->name;
        $r0  = $self->init->init->try_static_eval($env);
    }
    
    if ($self->init->isa('Bacon::Stmt::Expr')) {
        my $init = $self->init->expr;

        if ($init->isa('Bacon::Expr::BinaryOp') 
                && $init->name eq '='
                && $init->arg0->isa('Bacon::Expr::Identifier')) {       
            $var = $init->arg0->name;
            $r0  = $init->arg1->try_static_eval($env);
        }
    }

    unless (defined $var && defined $r0) {
        $self->can_unroll(0);
        return;
    }

    if ($self->cond->isa('Bacon::Expr::BinaryOp')
            && $self->cond->is_const_cond($env, $var)) {
        ($cond, $rN) = $self->cond->normalize_const_cond($env, $var);
    }
    else {
        return;
    }

    if ($self->incr->isa('Bacon::Expr')) {
        $incr = $self->incr->normalize_increment($env, $var);
    }

    unless (defined $incr) {
        $self->can_unroll(0);
        return;
    }

    if ($self->body->mutates_variable($var)) {
        $self->can_unroll(0);
        return;
    }

    my $range = abs($rN - $r0);

    $self->can_unroll(1);
    $self->unroll_info(
        [$var, $r0, $rN, $range, $incr, $cond]);
}

sub unroll_full {
    my ($self, $env, $depth) = @_;

    my ($var, $r0, $rN, $range, $incr, $cond) = @{$self->unroll_info};
    my $code = '';

    unless (defined $cond) {
        die Dumper($self->unroll_info);
    }

    for (my $ii = $r0; eval "$ii $cond $rN"; $ii += $incr) {
        my $env1 = $env->update_with($var => $ii);
        $code .= $self->body->contents_to_opencl($env1, $depth);
    }

    return $code;
}

sub unroll_partial {
    my ($self, $env, $depth) = @_;
    my ($var, $r0, $rN, $range, $incr, $cond) = @{$self->unroll_info};
    my $factor = greatest_factor_not_above($range, $MAX_UNROLL_SIZE);
    my $loops = $range / $factor;

    my $unroll_init = "$var = $r0";
    my $unroll_incr = "$var += $factor * $incr";

    my $code = '';
    for (my $ii = 0; $ii < $factor; ++$ii) {
        my $body = $self->body->transform(sub {
            my ($node) = @_;
            if ($node->isa('Bacon::Expr::Identifier') && $node->name eq $var) {
                return mkop('+', $node, mklit($ii));
            }
            else {
                return $node;
            }
        });
        $code .= $body->contents_to_opencl($env, $depth + 1);
    }

    return $self->fill_section(
        opencl_code => $depth,
        init => $unroll_init,
        cond => $self->cond->to_ocl($env),
        incr => $unroll_incr,
        body => $code);
}

sub unroll {
    my ($self, $env, $depth) = @_;
    my ($var, $r0, $rN, $range, $incr, $cond) = @{$self->unroll_info};

    if ($range <= $MAX_UNROLL_SIZE) {
        #say "loop $var ($range) can be unrolled fully";
        return $self->unroll_full($env, $depth);
    }
    else {
        #say "loop $var ($range) can be partially unrolled";
        return $self->unroll_partial($env, $depth);
    }
}

sub to_opencl {
    my ($self, $env, $depth) = @_;
    $self->build_unroll_info($env);

    if ($self->can_unroll && $self->body->cost($env) < $MAX_UNROLL_COST) {
        return $self->unroll($env, $depth);
    }

    # Cannot unroll, so just generate the loop.
    #my $text = $self->cond->to_ocl($env);
    #say "Loop for $text can't unroll.";

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
