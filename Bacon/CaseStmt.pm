package Bacon::CaseStmt;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::LabeledStmt;
extends 'Bacon::Stmt';

__PACKAGE__->meta->make_immutable;
1;
