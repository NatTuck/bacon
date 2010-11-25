package Bacon::TypeInfo;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has info => (is => 'ro', isa => 'ArrayRef[Str]',
             default => sub {[]});

sub add {
    my ($self, $new_info) = @_;
    if (ref($new_info) eq 'Bacon::TypeInfo') {
        for my $ii (@{$new_info->info}) {
            push @{$self->info}, $new_info;
        }
    }
    else {
        push @{$self->info}, $new_info;
    }
}

__PACKAGE__->meta->make_immutable;
1;
