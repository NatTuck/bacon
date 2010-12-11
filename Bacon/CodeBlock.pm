package Bacon::CodeBlock;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Data::Dumper;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has body => (is => 'rw', isa => 'ArrayRef[Bacon::Stmt]',
    default => sub { [] });

sub new3 {
    my ($class, $tok, $vars, $smts) = @_;
    my @body = (@$vars, @$smts);

    my $self = Bacon::CodeBlock->new_from_token(undef => $_[1]);
    $self->update(body => \@body);
    return $self;
}

# Return a list of variable declarations in this block.
# 

sub declared_variables {
    my ($self) = @_;
    
    my @vars = ();

    for my $smt (@{$self->body}) {
        push @vars, $smt->declared_variables;
    }

    return @vars;
}

sub to_opencl {
    my ($self, $depth) = @_;
    my $code = indent($depth) . "{\n";
    $code .= $self->contents_to_opencl($depth);
    $code .= indent($depth) . "}\n";
    return $code;
}

sub contents_to_opencl {
    my ($self, $depth) = @_;
    my $code = '';

    for my $smt (@{$self->body}) {
        $code .= $smt->to_opencl($depth + 1);
    }

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
