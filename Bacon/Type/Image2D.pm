package Bacon::Type::Image2D;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Type::Array;
extends 'Bacon::Type::Array';



__PACKAGE__->meta->make_immutable;
1;
