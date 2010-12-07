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

sub gen_code {
    my ($self, $depth) = @_;
    my $code = "/* Function: " . $self->name . 
               " " . $self->source . " */\n";

    if ($self->kern) {
        $code .= "kernel\n";
    }
        
    $code .= $self->return_type . "\n";

    $code .= $self->name . "(";
    $code .= join(', ', map {$_->gen_code(0)} @{$self->args});
    $code .= ")\n";
    
    if ($self->kern) {
        my @dims = map { $_->gen_code(0) } @{$self->dist};
        $code .= " @ [ " . join(', ', @dims) . "]\n";
    }

    $code .= $self->body->gen_code(0);

    $code .= "\n";

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
