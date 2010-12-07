package Bacon::Function;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;

use Bacon::AstNode;
extends 'Bacon::AstNode';

has name => (is => 'rw', isa => 'Str');
has args => (is => 'rw', isa => 'ArrayRef[Bacon::Variable]');
has retv => (is => 'rw', isa => 'Maybe[Bacon::Variable]');
has body => (is => 'rw', isa => 'Bacon::CodeBlock');
has kern => (is => 'rw', isa => 'Bool', default => 0);
has dist => (is => 'rw', isa => 'Maybe[ArrayRef[Bacon::Expr]]');

sub new_parts {
    my ($class, $specs, $decl, $body) = @_;
    my $self = $decl->update_with($specs);
    $self->kern(0);
    $self->dist(undef);
    $self->body($body);
    return $self;
}

sub new_kernel {
    my ($class, $self, $rtype, $dist, $body) = @_;
    $self->kern(1);
    $self->dist($dist);
    $self->retv($rtype);
    $self->body($body);
    return $self;
}

sub return_type {
    my ($self) = @_;
    return "void" unless (defined $self->retv);
    return $self->retv->type;
}

sub to_opencl {
    my ($self, $depth) = @_;
    my $code = "/* Function: " . $self->name . 
               " " . $self->source . " */\n";

    if ($self->kern) {
        my @dims = map { $_->to_opencl(0) } @{$self->dist};
        $code .= "kernel void\n";
        $code .= "/* returns: " . $self->return_type . "\n";
        $code .= " * distrib: ";
        $code .= " [" . join(', ', @dims) . "]\n";
        $code .= " */\n";
    }
    else {    
        $code .= $self->return_type . "\n";
    }

    $code .= $self->name . "(";
    $code .= join(', ', map {$_->to_opencl(0)} @{$self->args});
    $code .= ")\n";
    
    $code .= $self->body->to_opencl(0);

    $code .= "\n";

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
