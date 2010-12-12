package Bacon::Kernel;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;

use Bacon::Function;
extends 'Bacon::Function';

has dist => (is => 'rw', isa => 'Maybe[ArrayRef[Bacon::Expr]]');

use Bacon::Utils;

sub new4 {
    my ($class, $fun, $rtype, $dist, $body) = @_;
    my $self = $class->new_from_node($fun);
    $self->dist($dist);
    $self->retv($rtype);
    $self->body($body);
    return $self;
}

sub to_opencl {
    my ($self, $pgm) = @_;
    assert_type($pgm, "Bacon::Program");

    my $code = "/* Kernel: " . $self->name . 
               " " . $self->source . " */\n";

    my @dims = map { $_->to_opencl(0) } @{$self->dist};
    $code .= "kernel void\n";
    $code .= "/* returns: " . $self->return_type . "\n";
    $code .= " * distrib: ";
    $code .= " [" . join(', ', @dims) . "]\n";
    $code .= " */\n";

    my @args = $self->expand_vars(@{$self->args});
    $code .= $self->name . "(";
    $code .= join(', ', map {$_->to_opencl(0)} @args);
    $code .= ")\n";

    $code .= "{\n";
    
    my @vars = $self->expand_vars($self->find_decls);
    for my $var (@vars) {
        $code .= $var->decl_to_opencl(1);
    }

    $code .= $self->body->contents_to_opencl(0);

    $code .= "}\n\n";

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
