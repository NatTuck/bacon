package Bacon::Stmt::Error;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
# No namespace::autoclean with Bacon::Template

use Bacon::Stmt;
use Bacon::Template;
extends 'Bacon::Stmt', 'Bacon::Template';

has name => (is => 'ro', isa => 'Str', required => 1);
has args => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]', required => 1);

use Bacon::Utils;
use Bacon::Expr::String;

sub new2 {
    my ($class, $name, $args) = @_;
    return $class->new(name => $name, args => $args);
}

sub kids {
    my ($self) = @_;
    return @{$self->args};
}

sub to_opencl {
    my ($self, $env, $depth) = @_;

    given ($self->name) {
        when ('fail') { 
            return $self->gen_fail($env, $depth); 
        }
        when ('assert') {
            return $self->gen_assert($env, $depth);
        }
    }

    die "Unknown failure type: " . $self->name;
}

sub gen_fail {
    my ($self, $env, $depth) = @_;
    my $string = $self->args->[0];
    assert_type($string, 'Bacon::Expr::String');

    my $err_no   = $string->idx
        or die "No error number set";
    my $err_data = "0";

    if (scalar @{$self->args} > 1) {
        $err_data = $self->args->[1]->to_ocl($env); 
    }

    return $self->fill_section(
        "fail", $depth,
        err_no   => $err_no,
        err_data => $err_data,
    );
}

sub gen_assert {
    my ($self, $env, $depth) = @_;
    my $expr     = $self->args->[0]->to_ocl($env);
    my $string   = $self->args->[1];
    assert_type($string, 'Bacon::Expr::String');

    my $err_no   = $string->idx
        or die "No error number set";
    my $err_data = "0";

    if (scalar @{$self->args} > 2) {
        $err_data = $self->args->[2]->to_ocl($env); 
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
