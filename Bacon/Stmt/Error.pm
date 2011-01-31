package Bacon::Stmt::Error;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has name => (is => 'rw', isa => 'Str');
has args => (is => 'rw', isa => 'ArrayRef[Bacon::Expr]');

sub new2 {
    my ($class, $name, $args) = @_;
    return $class->new_from_token0(name => $name, args => $args);
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

    my $string = $self->args->[0]->value;
    my $err_no = $fun->lookup_error_string($string);
    
    my $code = indent($depth) . "_bacon__status[0] = $err_no;\n";
    
    if (scalar @{$self->args} > 1) {
        my $err_data = $self->args->[1]->to_ocl($fun); 
        $code .= indent($depth) . "_bacon__status[1] = $err_data;\n";
    }
    
    $code .= indent($depth) . "return;\n";
    return $code;
}

sub gen_assert {
    my ($self, $fun, $depth) = @_;

    my $expr   = $self->args->[0]->to_ocl($fun);
    my $string = $self->args->[1]->value;
    my $err_no = $fun->lookup_error_string($string);
    
    my $code = indent($depth) . "if ( !($expr) )";
    $code .= indent($depth) . "{\n";
    $code .= indent($depth + 1) . "_bacon__status[0] = $err_no;\n";
    
    if (scalar @{$self->args} > 2) {
        my $err_data = $self->args->[2]->to_ocl($fun); 
        $code .= indent($depth + 1) . "_bacon__status[1] = $err_data;\n";
    }
    
    $code .= indent($depth + 1) . "return;\n";
    $code .= indent($depth) . "}\n";
    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
