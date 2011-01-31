package Bacon::Variable;
use warnings FATAL => 'all';
use 5.10.0;
use feature 'switch';

use Moose;

has name => (is => 'ro', isa => 'Str', required => 1);
has type => (is => 'ro', isa => 'Str', required => 1);
has retv => (is => 'rw', isa => 'Bool', default => 0);

use Bacon::Utils;
use Bacon::Type::All;

sub new2 {
    my ($class, $name, $type) = @_;
    return $class->new(name => $name, type => $type);
}

sub expand {
    my ($self) = @_;
    if ($self->ptype) {
        my $type = $self->type_object;
        return $type->expand($self);
    }
    else {
        return ($self,);
    }
}

sub ptype {
    my ($self) = @_;
    if ($self->type =~ /^(.*)\<(.*)\>$/) {
        my ($ptype, undef) = ($1, $2);
        return $ptype;
    }
    else {
        return undef;
    }
}

sub subtype {
    my ($self) = @_;
    if ($self->type =~ /^(.*)\<(.*)\>$/) {
        my (undef, $subtype) = ($1, $2);
        return $subtype;
    }
    else {
        return undef;
    }
}

sub decl_fun_arg {
    my ($self, undef) = @_;
    my $code = "";
    $code .= "global " if ($self->type =~ /\*$/);
    $code .= $self->type . " ";
    $code .= $self->name;
    return $code;
}

sub cc_name {
    my ($self) = @_;
    return name_to_cc($self->name);
}

sub to_wrapper_hh {
    my ($self) = @_;
    return cpp_header_type($self->type) . ' ' . $self->name;
}

sub type_object {
    my ($self) = @_;
    my $ptype = $self->ptype
        or croak("Simple type has no type object");
    return "Bacon::Type::$ptype"->new1($self->subtype);
}

sub subnodes {
    my ($self) = @_;
    return ($self,);
}

1;
