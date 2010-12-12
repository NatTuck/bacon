package Bacon::Generate;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(bacon_generate);

use IO::Handle;

sub generate_opencl {
    my ($ast, $basefn) = @_;

    open my $out, ">", "gen/$basefn.cl";
    $out->print($ast->to_opencl(0));
    close($out);
}

sub generate_cpp {
    my ($ast) = @_;

}


sub bacon_generate {
    my ($ast) = @_;
    my $basefn = $ast->basefn;

    # Clean up the output directory.
    system "rm -rf ./gen";
    mkdir "gen";

    # Generate the OpenCL Code
    generate_opencl($ast, $basefn);

    # Generate the C++ wrapper code
    generate_cpp($ast);

    # Generate Makefile
}

1;
