package Bacon::Expr::BinaryOp;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
use Exporter;
extends 'Bacon::Expr', 'Exporter';

our @EXPORT_OK = qw(mkop);

use Data::Dumper;
use List::MoreUtils qw(any);
use Bacon::Utils;

has name => (is => 'ro', isa => 'Str', required => 1);
has arg0 => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has arg1 => (is => 'ro', isa => 'Bacon::Expr', required => 1);

sub mkop {
    my ($op, $aa, $bb) = @_;
    return __PACKAGE__->new3($op, $aa, $bb);
}

sub new3 {
    my ($class, $op, $aa, $bb) = @_;
    return $class->new_attrs(name => $op, arg0 => $aa, arg1 => $bb);
}

sub kids {
    my ($self) = @_;
    return ($self->arg0, $self->arg1);
}

sub is_cond {
    my ($self) = @_;
    my @cond_ops = qw(< > <= >= ==);

    for my $op (@cond_ops) {
        return 1 if ($op eq $self->name);
    }

    return 0;
}

sub is_const_cond {
    my ($self, $fun, $var) = @_;
    confess "No var specified" unless defined $var;

    return 0 unless $self->is_cond;

    unless ($self->arg0->is_const($fun) || $self->arg1->is_const($fun)) {
        return 0;
    }

    unless (($self->arg0->isa('Bacon::Expr::Identifier') && $self->arg0->name eq $var) 
         || ($self->arg1->isa('Bacon::Expr::Identifier') && $self->arg1->name eq $var)) {
        return 0;
    }

    return 1;
}

sub normalize_const_cond {
    my ($self, $fun, $var) = @_;
    die "That's not a constant condition" unless $self->is_const_cond($fun, $var);

    my $op = $self->name;
    my $num;

    if ($self->arg0->is_const($fun)) {
        $num = $self->arg0->static_eval($fun);
        # Flip the conditional 
        $op =~ tr/<>/></;
    }
    else {
        $num = $self->arg1->static_eval($fun);
    }

    return ($op, $num);
}

sub mutates_variable {
    my ($self, $var) = @_;
    my @mutating_ops = qw(= += -= *= /= %= &= ^= |= >>= <<=);

    if (any { $_->mutates_variable($var) } $self->kids) {
        return 1;
    }

    unless ($self->arg0->isa('Bacon::Expr::Identifier') && 
            $self->arg0->name eq $var) {
        return 0;
    }

    for my $op (@mutating_ops) {
        return 1 if ($op eq $self->name);
    }

    return 0;
}

sub normalize_increment {
    my ($self, $var) = @_;
    //// FIXME
    return undef;
}

sub static_eval {
    my ($self, $fun) = @_;
    my $op = $self->name;
    my $aa = $self->arg0->static_eval($fun);
    my $bb = $self->arg1->static_eval($fun);
    return 0 + eval "$aa $op $bb";
}

sub to_ocl {
    my ($self, $fun) = @_;
    return "("
        . $self->arg0->to_ocl($fun)
        . $self->name 
        . $self->arg1->to_ocl($fun) 
        . ")";
}

sub to_cpp {
    my ($self, $fun) = @_;
    return "("
        . $self->arg0->to_cpp($fun)
        . $self->name 
        . $self->arg1->to_cpp($fun) 
        . ")";
}

__PACKAGE__->meta->make_immutable;
1;
