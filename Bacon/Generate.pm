package Bacon::Generate;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(bacon_generate);

use IO::Handle;
use Text::Template;
use autodie;

sub generate_opencl {
    my ($ast) = @_;
    my $basefn = $ast->basefn;

    open my $out, ">", "gen/$basefn.cl";
    $out->print($ast->to_opencl);
    close($out);
}

sub generate_cpp {
    my ($ast) = @_;
    my $basefn = $ast->basefn;

    open my $hdr, ">", "gen/$basefn.hh";
    $hdr->print($ast->to_wrapper_hh);
    close($hdr);
    
    open my $cpp, ">", "gen/$basefn.cc";
    $cpp->print($ast->to_wrapper_cc);
    close($cpp);
}

sub gen_from_template {
    my ($file, %hash) = @_;

    my $tpl = Text::Template->new(
        TYPE => 'FILE',  
        SOURCE => "share/$file.tpl",
        DELIMITERS => ['<%', '%>']
    );

    open my $out, ">", "gen/$file";
    $out->print($tpl->fill_in(HASH => \%hash));
    close($out);
}

sub bacon_generate {
    my ($ast) = @_;
    my $basefn = $ast->basefn;

    # Clean up the output directory.
    system "rm -rf ./gen";
    mkdir "gen";

    # Generate the OpenCL Code
    generate_opencl($ast);

    # Generate the C++ wrapper code
    generate_cpp($ast);

    # Generate Makefile
    gen_from_template("Makefile", target => $basefn); 
}

1;
