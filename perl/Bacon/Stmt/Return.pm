package Bacon::Stmt::Return;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has expr => (is => 'ro', isa => 'Maybe[Bacon::Expr]', default => undef);

sub kids {
    my ($self) = @_;
    return ($self->expr,);
}

sub to_opencl {
    my ($self, $env, $depth) = @_;
    my $code = '';

    if ($env->in_kernel) {
        if (defined $self->expr) {
            assert_type($self->expr, "Bacon::Expr::Identifier");
            my $ridx = $env->lookup($self->expr->name)->ridx;
            $code .= indent($depth) . "_bacon__status[0] = $ridx;\n";
        }

        $code .= indent($depth) . "return;\n";
    }
    else {
        if (!defined $self->expr) {
            $code .= indent($depth) . "return;\n";
        }
        else {
            $code .= indent($depth) . "return "
                . $self->expr->to_ocl($env) . ";\n";
        }
    }
    
    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
