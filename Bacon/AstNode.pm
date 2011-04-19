package Bacon::AstNode;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has file => (is => 'ro', isa => 'Str', required => 1);
has line => (is => 'ro', isa => 'Int', required => 1);

use Bacon::Utils;

use Carp;
use Data::Dumper;
use Scalar::Util qw(blessed);
use Try::Tiny;
use Clone qw(clone);
use List::MoreUtils qw(any);

sub basefn {
    my ($self) = @_;
    my ($basefn) = $self->file =~ /^(.*)\.(bcn|bc)$/;
    return $basefn;
}

sub new_from_token0 {
    my ($class, $key, $token, @more) = @_;
    assert_type($token, 'Bacon::Token');

    if (defined $key) {
        @more = ($key => $token->text, @more);
    }

    return $class->new(
        file => $token->file, line => $token->line, @more
    );
}

sub new_attrs {
    my ($class, @data) = @_;
    my ($file, $line) = ('dunno', 12345678);

    for my $obj (reverse @data) {
        $file = $obj->file if(blessed($obj) && $obj->can('file'));
        $line = $obj->line if(blessed($obj) && $obj->can('line'));
        $obj = $obj->text
            if (blessed($obj) && $obj->isa('Bacon::Token'));
    }

    my $count = scalar @data;
    unless ($count % 2 == 0) {
        confess "Uneven array would make bad hash";
    }

    return $class->new(file => $file, line => $line, @data);
}

sub new_from_token {
    goto &new_attrs;
}

sub new_from_node {
    my ($class, $node) = @_;
    assert_type($node, 'Bacon::AstNode');
    my %attrs = (file => $node->file, line => $node->line);

    for my $attr_obj ($class->meta->get_all_attributes) {
        my $attr = $attr_obj->name;
        if ($node->meta->has_attribute($attr)) {
            $attrs{$attr} = $node->$attr;
        }
    }

    my $self = $class->new(%attrs);
    return $self;
}

sub update_with {
    my ($self, $other) = @_;
    assert_type($other, 'Bacon::AstNode');
    
    for my $attr_obj ($self->meta->get_all_attributes) {
        my $attr = $attr_obj->name;
        if ($other->meta->has_attribute($attr)) {
            unless (defined $self->$attr && $self->$attr) {
                $self->$attr($other->$attr);
                next;
            }
        
            if (defined $self->$attr && defined $other->$attr) {
                $self->$attr($self->$attr . " " . $other->$attr);
            }
        }
    }

    return $self; 
}

sub update {
    my ($self, @list) = @_;
    my %pairs = @list;

    for my $key (keys %pairs) {
        try {
            $self->$key($pairs{$key});
        }
        catch {
            warn "$_\n";
            warn "Error setting key '$key' to value:\n" 
                . Dumper($pairs{$key}) . "\n";
            confess "Giving up";
        };
    }

    return $self;
}

sub source {
    my ($self) = @_;
    return $self->file . ":" . $self->line;
}

sub declared_variables {
    my ($self) = @_;
    return ();
}

sub mutates_variable {
    my ($self, $var) = @_;
    return any { $_->mutates_variable($var) } $self->kids;
}

sub cost {
    my ($self, $fun) = @_;
    my $cost = 1;
    for my $kid ($self->kids) {
        $cost += $kid->cost($fun);
    }
    return $cost;
}

sub to_opencl {
    my ($self, undef, undef) = @_;
    my $type = ref $self ? ref $self : $self;
    confess "No method $type ::to_opencl. Did you want ::to_ocl?";
}

sub to_ocl {
    my ($self, undef) = @_;
    my $type = ref $self ? ref $self : $self;
    confess "No method $type ::to_ocl. Not an Expr?";
}

sub to_cpp {
    my ($self, undef) = @_;
    my $type = ref $self ? ref $self : $self;
    confess "No method $type ::to_cpp. Not an Expr?";
}

sub kids {
    my ($self) = @_;
    return ();
}

sub subnodes {
    my ($self) = @_;
    my @subnodes = ();
    for (grep { defined $_ } $self->kids) {
        push @subnodes, $_->subnodes;
    }
    return ($self, @subnodes);
}

__PACKAGE__->meta->make_immutable;
1;
