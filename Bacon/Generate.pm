package Bacon::Generate;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(bacon_generate_ast bacon_generate_ocl);

use IO::Handle;
use Text::Template;
use Storable qw(store retrieve);
use autodie;

use Bacon::CLEnv qw(ocl_write_perror ocl_ccflags ocl_ldflags);
use Bacon::TreeNodes;

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

    gen_from_template(
        "$basefn.hh", "UserClass.hh.tpl",
        name => $basefn, 
        prototypes => $ast->to_wrapper_hh,
    );

    gen_from_template(
        "$basefn.cc", "UserClass.cc.tpl",
        name => $basefn, 
        functions => $ast->to_wrapper_cc,
    );
}

sub gen_from_template {
    my ($file, $src, %hash) = @_;

    my $base = $ENV{BACON_BASE};

    my $tpl = Text::Template->new(
        TYPE => 'FILE',  
        SOURCE => "$base/share/$src",
        DELIMITERS => ['<%', '%>']
    ) or die "Template construction failed for $base/share/$src";

    open my $out, ">", "gen/$file";
    $out->print($tpl->fill_in(HASH => \%hash));
    close($out);
}

sub generate_ast {
    my ($ast, $fn) = @_;
    store($ast, $fn);
}

sub bacon_generate_ast {
    my ($ast) = @_;
    my $basefn = $ast->basefn;

    # Clean up the output directory.
    system "rm -rf ./gen";
    mkdir "gen";

    # Serialize the AST
    generate_ast($ast, "gen/$basefn.ast");

    # Temporary...
    #bacon_generate_ocl("gen/$basefn.ast");

    # Generate the C++ wrapper code
    generate_cpp($ast);

    # Generate Makefile
    gen_from_template("Makefile", "Makefile.tpl", 
        target  => $basefn,
        CCFLAGS => ocl_ccflags(),
        LDFLAGS => ocl_ldflags(),
    ); 

    # Copy some generic stuff.
    my $base = $ENV{BACON_BASE};
    my @files = grep { !/\.tpl$/ } `ls $base/share`;
    chomp @files;
    map { system("cp $base/share/$_ gen") } @files;

    system(qq{ln -s "$base/include/ocl" gen/ocl});

    # Generate opencl_perror code.
    ocl_write_perror("gen");    
}

sub bacon_generate_ocl {
    my ($ast_fn) = @_;
    generate_opencl(retrieve($ast_fn));
}

1;
