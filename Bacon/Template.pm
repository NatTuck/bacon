package Bacon::Template;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Text::Template;
use Data::Section -setup => { default_name => 'default' };

use Moose;
# No namespace::autoclean with Data::Section

extends 'Data::Section';

use Bacon::Utils;

sub indent_block {
    my ($depth, $text) = @_;
    my $code = '';
    for my $line (split /\n/, $text) {
        next unless $line =~ /\S/;
        $code .= indent($depth) . $line . "\n";
    }
    return $code;
}

sub fill_file {
    my ($self, $src, $depth, %hash) = @_;
    my $base = $ENV{BACON_BASE};

    my $tpl = Text::Template->new(
        TYPE => 'FILE',  
        SOURCE => "$base/share/$src",
        DELIMITERS => ['<%', '%>']
    ) or die "Template construction failed for $base/share/$src";

    return indent_block($depth, $tpl->fill_in(HASH => \%hash));
}

sub fill_section {
    my ($self, $sec, $depth, %hash) = @_;
    my $class = ref $self ? ref $self : $self;
    my $source = $self->section_data($sec)
        or confess "No such section: $sec";

    my $tpl = Text::Template->new(
        TYPE => 'STRING',  
        SOURCE => ${$source},
        DELIMITERS => ['<%', '%>'],
    ) or die "Template construction failed for section $sec in class $class"; 

    return indent_block($depth, $tpl->fill_in(HASH => \%hash));
}

__PACKAGE__->meta->make_immutable;
1;
