package Bacon::Token;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has type => (is => 'ro', isa => 'Str', required => 1);
has text => (is => 'ro', isa => 'Str', required => 1);
has file => (is => 'ro', isa => 'Str', required => 1);
has line => (is => 'ro', isa => 'Int', required => 1);

use Bacon::Utils qw(embiggen);

sub source {
    my ($self) = @_;
    return $self->file . ":" . $self->line;
}

sub number {
    my ($self) = @_;
    return embiggen($self->text);
}

__PACKAGE__->meta->make_immutable;
1;
