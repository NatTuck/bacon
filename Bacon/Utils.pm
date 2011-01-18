package Bacon::Utils;
use warnings FATAL => 'all';
use strict;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(indent assert_type in_list cpp_type cpp_header_type name_to_cc);

use Carp;
use Try::Tiny;

sub indent {
    my ($depth) = @_;
    try {
        return "    " x $depth;
    }
    catch {
        confess $_;
    };
}

sub assert_type {
    my ($obj, $expect_type) = @_;

    confess("Got undef instead of '$expect_type'")
        unless (defined $obj);

    confess("Got non-object instead of '$expect_type")
        unless (ref $obj);

    try {
        unless ($obj->isa($expect_type)) {
            my $actual_type = ref($obj);
            confess("Got type '$actual_type' instead of '$expect_type'");
        }
    } catch {
        confess("Exception: $_");
    };
}

sub in_list {
    my ($item, @list) = @_;
    for my $xx (@list) {
        return 1 if $item eq $xx;
    }
    return 0;
}

sub cpp_type {
    my ($type) = @_;

    return 'void' if($type eq 'void');

    if ($type =~ /^(\w)(.*)(\d\w)\<(.*)\>$/) {
        return uc($1) . ($2) . uc($3) . '<' . cpp_type($4) . '>';
    }
    else {
        return 'cl_' . $type;
    }
}

sub cpp_header_type {
    my ($type) = @_;
    $type = cpp_type($type);
    return ($type =~ /\<.*\>/)
        ? "Bacon::$type"
        : $type;
}

sub name_to_cc {
    my ($name) = @_;
    if ($name =~ /__/) {
        $name =~ s/__/./;
        $name =~ s/$/()/;
    }
    return $name;
}

1;
