package Bacon::Variable;
use warnings FATAL => 'all';
use 5.10.0;
use feature 'switch';

use Moose;
use Carp;

has name => (is => 'ro', isa => 'Str', required => 1);
has type => (is => 'ro', isa => 'Bacon::DataType', required => 1);
has retv => (is => 'rw', isa => 'Bool', default => 0);

use Bacon::Utils;
use Bacon::DataType;
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
    return 'PrivArray' if $self->type =~ /\*/;
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

    if ($self->ptype eq 'PrivArray') {
        confess "Derp?";
        my $type = $self->type;
        $type =~ s/\*//;
        return $type;
    }

    die "No subtype for primitive type" . $self->type;
}

sub struct_type {
    my ($self) = @_;
    unless ($self->ptype) {
        my $type = $self->type;
        croak "Simple type ($type) has no struct type: " . $self->name;
    }
    return undef if ($self->ptype eq 'PrivArray');
    return "_Bacon__" . $self->ptype . "__" . $self->subtype;
}

sub decl_fun_arg {
    my ($self, undef) = @_;
    my $code = "";
    if ($self->struct_type) {
        $code .= $self->struct_type . ' ' . $self->name;
    }
    else {
        $code .= "global " if ($self->type =~ /\*$/);
        $code .= $self->type . " ";
        $code .= $self->name;
    }
    return $code;
}

sub init_struct {
    my ($self) = @_;
    my $code = "";
    
    my $struct_type = $self->struct_type;
    my $type = $self->type_object;
    my $name = $self->name;

    $code .= indent(1) . "$struct_type $name;\n";
    $code .= indent(1) . "$name.data = $name" . "__data;\n";
    for my $dim (@{$type->dims}) {
        $code .= indent(1) . "$name.$dim = $name" . "__$dim;\n";
    }
    
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
    my $ptype = $self->ptype;
    unless ($ptype) {
        my $type = $self->type;
        croak "Simple type ($type) has no type object: " . $self->name;
    }
    return "Bacon::Type::$ptype"->new1($self->subtype);
}

sub subnodes {
    my ($self) = @_;
    return ($self,);
}

1;
