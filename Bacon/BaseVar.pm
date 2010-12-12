package Bacon::BaseVar;
use warnings FATAL => 'all';
use strict;
use 5.10.0;
use feature 'switch';

use Moose;
use namespace::autoclean;

use Carp;
use Data::Dumper;

has name => (is => 'ro', isa => 'Str', required => 1);
has type => (is => 'ro', isa => 'Str', required => 1);

sub expand {
    my ($self) = @_;
    if ($self->type =~ /^(.*)\<(.*)\>$/) {
        my ($ptype, $type) = ($1, $2);

        given ($ptype) {
            when ('array2d') { 
                return $self->expand_array2d($type)
            }
        }

        die "Unknown ptype: $ptype";
    }
    else {
        return ($self,);
    }
}

__PACKAGE__->meta->make_immutable;
1;
