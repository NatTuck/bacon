package Bacon::BuildVar;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;
use Carp;

extends 'Bacon::AstNode';

has type => (is => 'rw', isa => 'Maybe[Str]');
has name => (is => 'rw', isa => 'Maybe[Str]');
has dims => (is => 'rw', isa => 'Maybe[ArrayRef[Bacon::Expr]]');
has init => (is => 'rw', isa => 'Maybe[Bacon::Expr]');

use Bacon::Utils;

sub new_by_type {
    my ($class, $type) = @_;

    if ($type->isa('Bacon::Token')) {
        return $class->new_from_token(
            undef => $type, type => $type->text);
    }

    if ($type->isa('Bacon::BuildVar')) {
        return $class->new_from_node($type);
    }

    confess "What makes you think a " . ref($type) . " is a type?";
}

sub new_by_name {
    my ($class, $name) = @_;
    return $class->new_from_token(name => $name);
}

sub new_ptype {
    my ($class, $ptype, $param) = @_;
    my $tname = $ptype->text . "<" . $param->text . ">";
    return $class->new_from_token(undef => $ptype, type => $tname);
}

sub add_type {
    my ($self, $new_type) = @_;
    assert_type($new_type, 'Bacon::Token');

    my %types = ();
    $types{$new_type->text} = 1;
   
    for my $type (split /\s+/, $self->type) {
        $types{$type} = 1;
    }

    $self->type(join(' ', keys %types));
    return $self;
}

sub to_opencl {
    my ($self, $depth) = @_;
    confess "no name" unless $self->name;
    my $code = indent($depth);

    if ($self->type) {
        $code .= $self->type . " ";
    }

    $code .= $self->name;

    if (defined $self->dims) {
        my @dc = map { $_->to_opencl(0) } @{$self->dims};
        $code .= "[" . join(", ", @dc) . "]";
    }

    return $code;
}

sub expand {
    my ($self) = @_;
    warn Dumper($self) . "\n";
    confess "Type: " . $self->type;
    if ($self->type =~ /^(.*)\<(.*)\>$/) {
        my ($ptype, $type) = ($1, $2);    
        die "Found ptype: $ptype/$type";
    }
    else {
        return ($self,);
    }
}

sub decl_stmt {
    my ($self) = @_;
    confess "No name: " . Dumper($self) unless $self->name;
    confess "No type: " . Dumper($self) unless $self->type;

    confess "Array initializers not supported"
        if (defined $self->init && defined $self->dims);

    return Bacon::Stmt::VarDecl->new(
        file => $self->file, line => $self->line,
        type => $self->type, name => $self->name, 
        dims => $self->dims, init => $self->init
    );
}

sub fun_arg {
    my ($self) = @_;
    confess "No name: " . Dumper($self) unless $self->name;
    confess "No type: " . Dumper($self) unless $self->type;
    confess "Fun Args can't have dims" if $self->dims;

    return Bacon::Variable->new2($self->name, $self->type);
}

__PACKAGE__->meta->make_immutable;
1;
