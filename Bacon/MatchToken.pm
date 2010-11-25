package Bacon::MatchToken;
use strict;
use warnings FATAL => 'all';
use 5.10.0;

use Moose;
use Carp;
use namespace::autoclean;

has name  => (is => 'ro', isa => 'Str', required => 1);
has type  => (is => 'ro', isa => 'Str', required => 1);
has regex => (is => 'ro', isa => 'RegexpRef');
has exact => (is => 'ro', isa => 'Str');

around BUILDARGS => sub {
    my ($orig, $class, $name, $pattern) = @_;

    if ($pattern =~ /^\"(.*)\"$/) {
        my $exact = $1;
        return $class->$orig(name => $name, type => 'exact', exact => $exact);
    }
    elsif ($pattern =~ /^(\W\W?)$/) {
        my $exact = $1;
        return $class->$orig(name => $name, type => 'exact', exact => $exact);
    }
    else {
        my $regex = qr/$pattern/;
        return $class->$orig(name => $name, type => 'regex', regex => $regex);
    }
};

sub match {
    my ($self, $textref) = @_;

    if ($self->type eq 'exact') {
        my $len = length($self->exact);

        if (substr($$textref, 0, $len) eq $self->exact) {
            substr($$textref, 0, $len, '');
            return ($self->name, $self->exact);
        }
        else {
            #say substr($$textref, 0, $len) . " ne " . $self->exact;
            return undef;
        }
    }
    else {
        my $regex = $self->regex;

        if ($$textref =~ /^$regex/) {
            my $match = $&;
            $$textref =~ s/^$regex//;
            return ($self->name, $match); 
        }
        else {
            #say substr($$textref, 0, 8) . " !~ " . $regex;
            return undef;
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
