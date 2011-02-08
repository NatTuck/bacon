package Bacon::Variable;
use warnings FATAL => 'all';
use 5.10.0;

die "Finish this stuff.";

use Moose;
use namespace::autoclean;

has addr_scope => (is => 'rw', isa => 'Str', default => 'local');
has param_type => (is => 'rw', isa => 'Str', default => '');
has basic_type => (is => 'rw', isa => 'Str', default => '');

sub new_by_scope {
    my ($class, $scope) = @_;
    return $class->new(addr_scope => $scope);
}

sub new_by_ptype {
    my ($class, $ptype) = @_;
    return $class->new(param_type => $ptype);
}

sub new_by_type {
    my ($class, $btype) = @_;
    return $class->new(basic_type => $btype);
}



__PACKAGE__->meta->make_immutable;
1;
