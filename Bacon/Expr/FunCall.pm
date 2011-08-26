package Bacon::Expr::FunCall;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

use Bacon::Utils;
use Data::Dumper;

has name => (is => 'ro', isa => 'Str', required => 1);
has args => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]', required => 1);

sub new_args {
    my ($class, $op, @args) = @_;
    return $class->new_from_token0(name => $op, args => [@args]);
}

sub kids {
    my ($self) = @_;
    return @{$self->args};
}

sub to_ocl {
    my ($self, $env) = @_;
    my $name = $self->name;

    my $fun = $env->funs->{$name};

    unless (defined $fun) {
        # External function.
        my @args = @{$self->args};
        my @ac   = map { $_->to_ocl($env) } @args;
        return $name
            . '(' 
            . join(', ', @ac) 
            . ')';
    }

    # Local function
    # Needs to be specialized

    my $NN = scalar @{$self->args};
    confess "Argument count mismatch in $name(...)"
        if ($NN != scalar @{$fun->args});

    my @const_vals = ();
    my %cv_by_name = ();

    for (my $ii = 0; $ii < $NN; ++$ii) {
        my $slot = $fun->args->[$ii];
        my $expr = $self->args->[$ii];
        
        if ($slot->is_const) {
            my $nn = $slot->name;
            my $vv = $expr->static_eval($env);
            say "$nn = vv";

            push @const_vals, $vv;
            $cv_by_name{$nn} = $vv;
            next;
        }

        if ($slot->has_dims) {
            assert_type($expr, 'Bacon::Expr::Identifier');

            for my $dim (@{$slot->type->dims}) {
                my $nn = $slot->name . '.' . $dim;
                my $dim_expr = Bacon::Expr::FieldAccess->new2(
                    $expr->name, $dim);
                my $vv = $dim_expr->static_eval($env);

                unless (defined $vv) {
                    say "Cannot static eval arg $nn for $name";
                    say Dumper($expr);
                    $env->dump_values();
                    croak();
                }

                say "$nn = $vv";

                push @const_vals, $vv;
                $cv_by_name{$nn} = $vv;
                next;
            }
        }
    }

    # FIXME: Finish specializations here.

    croak("All done");
}

sub to_cpp {
    my ($self, $fun) = @_;

    my @args = @{$self->args};
    my @ac   = map { $_->to_cpp($fun) } @args;
    return $self->name 
        . '(' 
        . join(', ', @ac) 
        . ')';
}

__PACKAGE__->meta->make_immutable;
1;
