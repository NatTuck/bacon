package Bacon::Variable;
use warnings FATAL => 'all';
use 5.10.0;
use feature 'switch';

use Moose::Role;

has name => (is => 'ro', isa => 'Str', required => 1);
has type => (is => 'ro', isa => 'Str', required => 1);
has retv => (is => 'rw', isa => 'Bool', default => 0);

use Bacon::Utils qw(name_to_cc);

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

sub cc_name {
    my ($self) = @_;
    return name_to_cc($self->name);
}

1;
