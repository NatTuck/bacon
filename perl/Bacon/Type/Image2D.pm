package Bacon::Type::Image2D;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Carp;

use Bacon::Type::Image;
extends 'Bacon::Type::Image';

has '+dims' => (default => sub { ['rows', 'cols'] });

sub index_expr {
    my ($self, $var, $env, $row, $col) = @_;
    confess "Cannot generate index expression for image.";
}

sub image_read_to_ocl {
    my ($self, $var, $env, $row, $col) = @_;
    my $row_expr = $row->to_ocl($env);
    my $col_expr = $col->to_ocl($env);
    my $var_name = $var->name;
    my $subtype  = $self->subtype->type;
    return "_bacon__image2d_read_$subtype($var_name, $row_expr, $col_expr)";
}

sub image_write_to_ocl {
    my ($self, $var, $env, $row, $col, $value) = @_;
    my $row_expr = $row->to_ocl($env);
    my $col_expr = $col->to_ocl($env);
    my $val_expr = $value->to_ocl($env);
    my $var_name = $var->name;
    my $subtype  = $self->subtype->type;
    return "_bacon__image2d_write_$subtype($var_name, $row_expr, $col_expr, $val_expr)";
}

sub to_ocl {
    my ($self) = @_;
    given ($self->mode) {
        when ('ro') { 
            return "read_only image2d_t";
        }
        when ('wo') { 
            return "write_only image2d_t"; 
        }
        default { 
            confess "Invalid mode for Image2D type.";
        }      
    }
}

__PACKAGE__->meta->make_immutable;
1;
