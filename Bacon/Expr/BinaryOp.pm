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

sub static_eval {
    my ($self, $fun) = @_;
    my $op = $self->name;
    my $aa = $self->arg0->static_eval($fun);
    my $bb = $self->arg1->static_eval($fun);
    return eval "$aa $op $bb";
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
