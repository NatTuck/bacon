package Bacon::Type::Array;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Type::Base;
extends 'Bacon::Type::Base';

__PACKAGE__->meta->make_immutable;
1;
