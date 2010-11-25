package Bacon::Func;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has name => (is => 'ro', isa => 'Str', required => 1);
has args => (is => 'ro', isa => 'ArrayRef[Bacon::Variable]', required => 1);
has retv => (is => 'ro', isa => 'Bacon::Variable', required => 1);
has vars => (is => 'ro', isa => 'ArrayRef[Bacon::Variable]', required => 1);
has body => (is => 'ro', isa => 'ArrayRef[Bacon::Stmt]', required => 1);
has kern => (is => 'ro', isa => 'Bool', required => 1);
has dims => (is => 'ro', isa => 'ArrayRef[Int]');

__PACKAGE__->meta->make_immutable;
1;
