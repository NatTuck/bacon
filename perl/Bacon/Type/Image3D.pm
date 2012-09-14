package Bacon::Type::Image3D;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Carp;

use Bacon::Type::Image;
extends 'Bacon::Type::Image';

has '+dims' => (default => sub { ['deep', 'rows', 'cols'] });

sub index_expr {
    my ($self, $var, $env, $dep, $row, $col) = @_;
    confess "Cannot generate index expression for image.";
}

sub image_read_to_ocl {
    my ($self, $var, $env, $dep, $row, $col) = @_;
    my $dep_expr = $dep->to_ocl($env);
    my $row_expr = $row->to_ocl($env);
    my $col_expr = $col->to_ocl($env);
    my $var_name = $var->name;
    my $subtype  = $self->subtype->type;
    return "_bacon__image3d_read_$subtype($var_name, $dep_expr, $row_expr, $col_expr)";
}

sub image_write_to_ocl {
    my ($self, $var, $env, $dep, $row, $col, $value) = @_;
    my $dep_expr = $dep->to_ocl($env);
    my $row_expr = $row->to_ocl($env);
    my $col_expr = $col->to_ocl($env);
    my $val_expr = $value->to_ocl($env);
    my $var_name = $var->name;
    my $subtype  = $self->subtype->type;
    return "_bacon__image3d_write_$subtype($var_name, $dep_expr, $row_expr, $col_expr, $val_expr)";
}

sub to_ocl {
    my ($self) = @_;
    given ($self->mode) {
        when ('ro') { 
            return "read_only image3d_t";
        }
        when ('wo') { 
            return "write_only image3d_t"; 
        }
        default { 
            confess "Invalid mode for Image3D type.";
        }      
    }
}

__PACKAGE__->meta->make_immutable;
1;
