package Bacon::Expr::ArrayIndex;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Try::Tiny;
use Data::Dumper;

use Bacon::Expr;
extends 'Bacon::Expr';

has name => (is => 'ro', isa => 'Str', required => 1);
has dims => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]', required => 1);

use Bacon::Expr::FieldAccess;
use Bacon::Expr::BinaryOp qw(mkop);
use Bacon::Utils;

sub new_dims {
    my ($class, $name, @dims) = @_;
    return $class->new_attrs(name => $name, dims => [@dims]);
}

sub kids {
    my ($self) = @_;
    return @{$self->dims};
}

sub to_ocl {
    my ($self, $fun) = @_;
    try {
        my $var  = $fun->lookup_variable($self->name);
        my $type = $var->type;
        my $code = $type->index_to_ocl($self, $fun, @{$self->dims});
        return $code;
    } catch {
        my $source = $self->source;
        warn "At $source, in an array index:\n";
        die "$_";
    };
}

sub to_cpp {
    my ($self, $fun) = @_;
    return $self->name . ".get"
        . '('
        . join(', ', map { $_->to_cpp($fun) } @{$self->dims})
        . ')'
}

__PACKAGE__->meta->make_immutable;
1;
