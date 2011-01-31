package Bacon::Template;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Text::Template;
use Data::Section;

use Moose;
use namespace::autoclean;

extends 'Data::Section';

sub fill_file {
    my ($self, $src, %hash) = @_;
    my $base = $ENV{BACON_BASE};

    my $tpl = Text::Template->new(
        TYPE => 'FILE',  
        SOURCE => "$base/share/$src",
        DELIMITERS => ['<%', '%>']
    ) or die "Template construction failed for $base/share/$src";

    return $tpl->fill_in(HASH => \%hash);
}

sub fill_section {
    my ($self, $sec, %hash) = @_;
    my $class = ref $self ? ref $self : $self;

    my $tpl = Text::Template->new(
        TYPE => 'STRING',  
        SOURCE => $self->section_data($sec),
        DELIMITERS => ['<%', '%>']
    ) or die "Template construction failed for section $sec in class $class"; 

    return $tpl->fill_in(HASH => \%hash);    
}

__PACKAGE__->meta->make_immutable;
1;
