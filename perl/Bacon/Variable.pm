package Bacon::Variable;
use warnings FATAL => 'all';
use 5.10.0;
use feature 'switch';

use Moose;

use Carp;
use Data::Dumper;
use Bacon::BigNum;

has name  => (is => 'ro', isa => 'Str', required => 1);
has type  => (is => 'ro', isa => 'Maybe[Bacon::Type]');

has ridx  => (is => 'rw', isa => 'Maybe[Num]');
has value => (is => 'rw', isa => 'Maybe[BigNum]');

use Bacon::Utils;
use Bacon::Type::All;

sub expand {
    my ($self) = @_;
    return $self->type->expand($self);
}

sub to_kern_arg {
    my ($self, undef) = @_;
    if ($self->has_struct) {
        $self->type->data_var($self)->to_kern_arg;
    }
    else {
        return $self->type->to_ocl . ' ' . $self->name;
    }
}

sub to_fun_arg {
    my ($self, undef) = @_;
    return $self->type->to_ocl . ' ' . $self->name;
}

sub has_struct {
    my ($self) = @_;
    return $self->type_isa("Bacon::Type::Array")
       && !$self->type_isa("Bacon::Type::Image");
}

sub is_const {
    my ($self) = @_;
    return $self->type->qualifier eq 'const';
}

sub has_dims {
    my ($self) = @_;
    return $self->type_isa("Bacon::Type::Array");
}

sub type_isa {
    my ($self, $type) = @_;
    return defined($self->type) && $self->type->isa($type);
}

sub dim_vars {
    my ($self) = @_;
    my @vars = ();

    return @vars unless $self->has_dims;

    for my $dim (@{$self->type->dims}) {
        my $var = Bacon::Variable->new(
            name => $self->name . ".$dim",
            type => Bacon::Type::Simple->new1("uint"));
        push @vars, $var;
    }

    return @vars;
}

sub init_struct {
    my ($self, $env) = @_;
    assert_type($env, 'Bacon::Environment');
    my $code = "";

    my $type = $self->type;
    my $name = $self->name;

    my $struct_type = $self->type->to_ocl;

    $code .= indent(1) . "$struct_type $name;\n";
    $code .= indent(1) . "$name.data = $name" . "__data;\n";

    for my $dim (@{$type->dims}) {
        my $dval = $env->value("$name.$dim");
        $code .= indent(1) . "$name.$dim = $dval;\n";
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

    if ($self->has_dims) {
        return name_to_cc($self->name) . '.data()';
    }

    return name_to_cc($self->name);
}

sub subnodes {
    my ($self) = @_;
    return ($self,);
}

1;
