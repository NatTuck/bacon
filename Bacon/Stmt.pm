package Bacon::Stmt;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has type => (is => 'ro', isa => 'Str', required => 1);
has args => (is => 'ro', isa => 'Item');

__PACKAGE__->meta->make_immutable;
1;
