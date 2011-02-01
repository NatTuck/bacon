package Bacon::CLEnv;
use warnings FATAL => 'all';
use strict;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(ocl_ccflags ocl_ldflags ocl_write_perror);

sub find_opencl_config {
    my $CL_INC = "";
    my $CL_LIB = "";
    my $CL_VER = "";

    my $ARCH = `uname -m`;
    chomp $ARCH;

    if ($ENV{ATISTREAMSDKROOT}) {
        my $base = $ENV{ATISTREAMSDKROOT};
        $CL_INC = "$base/include";
        $CL_LIB = "$base/lib/$ARCH";
        $CL_VER = "ATI";
    }

    if (-d "/usr/local/cuda") {
        $CL_INC = "/usr/local/cuda/include";
        $CL_VER = "Nvida";
    }

    return (
        ver => $CL_VER,
        inc => $CL_INC,
        lib => $CL_LIB,
    );
}

sub ocl_ccflags {
    my %cfg = find_opencl_config();
    my $base = $ENV{BACON_BASE};
    return  qq{-I "} . $cfg{inc} . qq{" -I "$base/include"};
}

sub ocl_ldflags {
    my %cfg = find_opencl_config();
    my $base = $ENV{BACON_BASE};

    my $ldflags = qq{-L "$base/lib" -lbacon };

    if ($cfg{lib}) {
        $ldflags .= '-L "' . $cfg{lib} . '" ' . $ldflags;
    }

    $ldflags .= " -lOpenCL";



    return $ldflags;
}

sub ocl_write_perror {
    my ($outdir) = @_;

    my %cfg = find_opencl_config();
    my $INCDIR = $cfg{inc};

    my %CODES = ();
    
    open my $clh, "<", "$INCDIR/CL/cl.h";
    while (<$clh>) {
        next unless /^#define\s+(CL_\w+)\s+(-?\d+)/;
        my ($code, $symbol) = ($2, $1);
        next if ($code == 0 || $code == 1);
    
        $CODES{$code} = $symbol;
    }
    close $clh;
    
    open my $clcc, ">", "$outdir/cl_perror.cc";
    $clcc->print(<<"HEAD");
// This file is generated automatically.
// Any changes you make will be lost.
    
#include <string>
using std::string;
    
#include <iostream>
using std::cerr;
using std::endl;
    
#include "cl_perror.hh"
    
string
cl_strerror(int code)
{
    switch (code) {
HEAD
    
    for my $code (reverse sort { $a <=> $b } keys %CODES) {
        my $symbol = $CODES{$code};
        $clcc->print(qq{    case $code:\n});
        $clcc->print(qq{        return string("$symbol");\n});
    }
    
    $clcc->print(<<"FOOT");
    default:
        return string("UNKNOWN_ERROR_CODE");
    };
}
    
void
cl_perror(int code)
{
    cerr << "OpenCL error: " << cl_strerror(code) << endl;
}
FOOT
    close $clcc;
    
    open my $clhh, ">", "$outdir/cl_perror.hh";
    $clhh->print(<<"HEADER");
#ifndef CL_PERROR_HH
#define CL_PERROR_HH
    
// This file is generated automatically.
// Any changes you make will be lost.
    
std::string cl_strerror(int code);
void cl_perror(int code);
    
#endif
HEADER
    close $clhh; 
}

1;
