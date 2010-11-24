package Bacon::Program;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has globals => (is => 'rw', isa => 'ArrayRef[Bacon::Variable]', 
                default => sub {[]} );
has funcs   => (is => 'rw', isa => 'ArrayRef[Bacon::Func]',
                default => sub {[]} );

use Data::Dumper;

sub add {
    my ($self, $def) = @_;
    say "got def: ", Dumper($def);
    push @{$self->globals}, $def;
}

__PACKAGE__->meta->make_immutable;
1;
