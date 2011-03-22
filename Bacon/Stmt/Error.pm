package Bacon::Stmt::Error;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
# No namespace::autoclean with Bacon::Template

use Bacon::Stmt;
use Bacon::Template;

extends 'Bacon::Stmt', 'Bacon::Template';

use Bacon::Utils;

has name => (is => 'rw', isa => 'Str');
has args => (is => 'rw', isa => 'ArrayRef[Bacon::Expr]');

sub new2 {
    my ($class, $name, $args) = @_;
    return $class->new_from_token0(name => $name, args => $args);
}

sub kids {
    my ($self) = @_;
    return @{$self->args};
}

sub to_opencl {
    my ($self, $fun, $depth) = @_;

    given ($self->name) {
        when ('fail') { 
            return $self->gen_fail($fun, $depth); 
        }
        when ('assert') {
            return $self->gen_assert($fun, $depth);
        }
    }

    die "Unknown failure type: " . $self->name;
}

sub gen_fail {
    my ($self, $fun, $depth) = @_;

    my $string   = $self->args->[0]->value;
    my $err_no   = $fun->lookup_error_string($string);
    my $err_data = "0";

    if (scalar @{$self->args} > 1) {
        $err_data = $self->args->[1]->to_ocl($fun); 
    }

    return $self->fill_section(
        "fail", $depth,
        err_no   => $err_no,
        err_data => $err_data,
    );
}

sub gen_assert {
    my ($self, $fun, $depth) = @_;

    my $expr     = $self->args->[0]->to_ocl($fun);
    my $string   = $self->args->[1]->value;
    my $err_no   = $fun->lookup_error_string($string);
    my $err_data = "0";

    if (scalar @{$self->args} > 2) {
        $err_data = $self->args->[2]->to_ocl($fun); 
    }

    return $self->fill_section(
        "assert", $depth,
        expr     => $expr,
        err_no   => $err_no,
        err_data => $err_data,
    );
}

__PACKAGE__->meta->make_immutable;
1;

__DATA__

__[ fail ]__

_bacon__status[1] = <% $err_no %>;
_bacon__status[2] = <% $err_data %>;
return;

__[ assert ]__

if ( !(<% $expr %>) ) {
    _bacon__status[1] = <% $err_no %>;
    _bacon__status[2] = <% $err_data %>;
    return;
}
