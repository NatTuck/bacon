package Bacon::CodeBlock;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

has vars => (is => 'rw', isa => 'ArrayRef[Bacon::Variable]');
has code => (is => 'rw', isa => 'ArrayRef[Bacon::Stmt]');

__PACKAGE__->meta->make_immutable;
1;
