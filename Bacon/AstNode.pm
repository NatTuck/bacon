package Bacon::AstNode;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has source => (is => 'ro', isa => 'Str', required => 1);

use Bacon::Utils;

use Carp;
use Data::Dumper;
use Scalar::Util qw(blessed);
use Try::Tiny;
use Clone qw(clone);
use List::MoreUtils qw(any);

around BUILDARGS => sub {
    my ($orig, $class, %raw_args) = @_;
    my %args = ();

    # Copy args, translate tokens, and find source info.
    for my $key (keys %raw_args) {
        my $value = $raw_args{$key};

        if ($key eq 'token') {
            assert_type($value, 'Bacon::Token');
            $args{source} = $value->source;
        }
        elsif (blessed($value) && $value->isa("Bacon::Token")) {
            unless (defined $args{source}) {
                $args{source} = $value->source;
            }
            $args{$key} = $value->text;
        }
        elsif (blessed($value) && $value->isa("Bacon::AstNode")) {
            unless (defined $args{source}) {
                $args{source} = $value->source;
            }
            $args{$key} = $value;
        }
        else {
            $args{$key} = $value;
        }      
    }

    confess "No source given" unless defined $args{source};

    return $class->$orig(%args);
};

sub new0 {
    my ($class, %args) = @_;
    return $class->new(source => "dunno:0", %args);
}

sub basefn {
    my ($self) = @_;
    my ($basefn) = $self->source =~ /^(.*)\.(bcn|bc):\d+$/;
    return $basefn;
}

sub declared_variables {
    my ($self) = @_;
    return ();
}

sub mutates_variable {
    my ($self, $var) = @_;
    return any { $_->mutates_variable($var) } $self->kids;
}

sub cost {
    my ($self, $env) = @_;
    my $cost = 1;
    for my $kid ($self->kids) {
        $cost += $kid->cost($env);
    }
    return $cost;
}

sub partial_eval {
    my ($self, $env) = @_;
    my $class = ref($self);
    my @attrs = $class->meta->get_all_attributes;
    my %copy  = ();

    for my $attr (@attrs) {
        my $value = $self->$attr;
        if (blessed($value) && $value->can('partial_eval')) {
            $copy{$attr} = $value->partial_eval($env);
        }
        else {
            $copy{$attr} = clone($value);
        }
    }

    return $class->new(%copy);
}

sub to_opencl {
    my ($self, undef, undef) = @_;
    my $type = ref $self ? ref $self : $self;
    confess "No method $type ::to_opencl. Did you want ::to_ocl?";
}

sub to_ocl {
    my ($self, undef) = @_;
    my $type = ref $self ? ref $self : $self;
    confess "No method $type ::to_ocl. Not an Expr?";
}

sub to_cpp {
    my ($self, undef) = @_;
    my $type = ref $self ? ref $self : $self;
    confess "No method $type ::to_cpp. Not an Expr?";
}

sub kids {
    my ($self) = @_;
    return ();
}

sub subnodes {
    my ($self) = @_;
    my @subnodes = ();
    for (grep { defined $_ } $self->kids) {
        push @subnodes, $_->subnodes;
    }
    return ($self, @subnodes);
}

__PACKAGE__->meta->make_immutable;
1;
