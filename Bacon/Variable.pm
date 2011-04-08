package Bacon::Variable;
use warnings FATAL => 'all';
use 5.10.0;
use feature 'switch';

use Moose;
use Carp;

has name => (is => 'ro', isa => 'Str', required => 1);
has type => (is => 'rw', isa => 'Maybe[Bacon::Type]');

has static_value => (is => 'rw', isa => 'Maybe[Num');

use Bacon::Utils;
use Bacon::Type::All;

sub expand {
    my ($self) = @_;
    return $self->type->expand($self);
}

sub to_kern_arg {
    my ($self, undef) = @_;
    return $self->type->to_ocl . ' ' . $self->name;
}

sub to_fun_arg {
    my ($self, undef) = @_;
    return $self->type->to_ocl . ' ' . $self->name;
}

sub has_struct {
    my ($self) = @_;
    return $self->type->isa("Bacon::Type::Array");
}

sub is_const {
    my ($self) = @_;
    return $self->type->qualifier eq 'const';
}

sub has_dims {
    my ($self) = @_;
    return $self->has_struct;
}

sub init_struct {
    my ($self) = @_;
    my $code = "";

    my $type = $self->type;
    my $name = $self->name;

    my $struct_type = $self->type->to_ocl;

    $code .= indent(1) . "$struct_type $name;\n";
    $code .= indent(1) . "$name.data = $name" . "__data;\n";

    for my $dim (@{$type->dims}) {
        $code .= indent(1) . "$name.$dim = $name" . "__$dim;\n";
    }
    
    return $code;
}

sub to_wrapper_hh {
    my ($self) = @_;
    my $type = $self->type->to_cpp;
    $type .= '&' if ($type =~ /\<.*\>/);
    return $type . ' ' . $self->name;
}

sub cc_name {
    my ($self) = @_;
    if ($self->type->scope eq 'local') {
        my $name = $self->name;
        $name =~ s/__data$//;
        return "cl::__local($name.byte_size())";
    }
    else {
        return name_to_cc($self->name);
    }
}

sub subnodes {
    my ($self) = @_;
    return ($self,);
}

1;
