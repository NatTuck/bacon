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

    my $self = $class->new(file => $node->file, line => $node->line);

    for my $attr_obj ($self->meta->get_all_attributes) {
        my $attr = $attr_obj->name;
        if ($node->meta->has_attribute($attr)) {
            $self->$attr($node->$attr);
        }
    }
    
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

sub gen_code {
    my (undef, $depth) = @_;
    return indent($depth || 0) . "** ???? **";
}

__PACKAGE__->meta->make_immutable;
1;
