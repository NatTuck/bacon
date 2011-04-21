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
    my ($self, $fun, $depth) = @_;
    my $code = '';

    if ($fun->isa("Bacon::Kernel")) {
        if (defined $self->expr) {
            die "Must return exactly one variable"
                unless ($self->expr->isa("Bacon::Expr::Identifier"));
        }
        
        $code .= indent($depth) . "return;\n";
    }
    else {
        if (!defined $self->expr) {
            $code .= indent($depth) . "return;\n";
        }
        else {
            $code .= indent($depth) . "return "
                . $self->expr->to_ocl($fun) . ";\n";
        }
    }
    
    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
