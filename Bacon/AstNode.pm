package Bacon::AstNode;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has file => (is => 'ro', isa => 'Str', required => 1);
has line => (is => 'ro', isa => 'Int', required => 1);

use Bacon::Utils;

use Data::Dumper;
use Try::Tiny;
use Clone qw(clone);

sub basefn {
    my ($self) = @_;
    my ($basefn) = $self->file =~ /^(.*)\.(bcn|bc)$/;
    return $basefn;
}

sub new_from_token {
    my ($class, $key, $token, @more) = @_;
    assert_type($token, 'Bacon::Token');

    if (defined $key) {
        @more = ($key => $token->text, @more);
    }

    return $class->new(
        file => $token->file, line => $token->line, @more
    );
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
                $self->attr($self->$attr . " " . $other->$attr);
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

sub to_opencl {
    my (undef, $depth) = @_;
    return indent($depth || 0) . "** ???? **";
}

sub kids {
    my ($self) = @_;
    return ();
}

sub find_decls {
    my ($self) = @_;
    my @decls = ();
    push @decls, $_->find_decls for $self->kids;
    return @decls;
}

__PACKAGE__->meta->make_immutable;
1;
