package Bacon::Type;
use warnings FATAL => 'all';
use 5.10.0;

use Moose;
use namespace::autoclean;

use Carp;
use Data::Dumper;

has qualifier => (is => 'rw', isa => 'Str', default => '');

use Bacon::Type::All;

sub new_ptype {
    my (undef, $ptype, $subtype_name, $scope) = @_;
    my $subtype = Bacon::Type::Simple->new1($subtype_name);
    return "Bacon::Type::$ptype"->new1($subtype, $scope);
}

sub add_qualifier {
    my ($self, $qual) = @_;
    if ($self->qualifier) {
        die "Add qualifier $qual to " . $self->qualifier;
    }
    $self->qualifier($qual);
    return $self;
}

sub type {
    my ($self) = @_;
    my $class = ref $self;
    $class =~ /::([^:]+)$/;
    return $1;
}

sub is_void {
    my ($self) = @_;
    return 0;
}

sub expand {
    my ($self, $var) = @_;
    return ($var,);
}

sub to_kern_arg {
    my ($self) = @_;
    return $self->to_ocl;
}

sub is_returnable {
    my ($self) = @_;
    return 1;
}

__PACKAGE__->meta->make_immutable;
1;
