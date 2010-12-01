package Bacon::Literal;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

has value => (is => 'ro', isa => 'Str', required => 1);

__PACKAGE__->meta->make_immutable;
1;
