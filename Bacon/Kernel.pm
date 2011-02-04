package Bacon::Kernel;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;

use Bacon::Function;
extends 'Bacon::Function';

has dist => (is => 'rw', isa => 'Maybe[ArrayRef[Bacon::Expr]]');

use Bacon::Utils;

sub new4 {
    my ($class, $fun, $rtype, $dist, $body) = @_;
    assert_type($body, 'Bacon::Stmt::Block');
    my $self = $class->new(
        file => $fun->file, line => $fun->line,
        name => $fun->name, args => $fun->args,
        retv => $rtype, body => $body, dist => $dist
    );
    return $self;
}

sub lookup_error_string {
    my ($self, $string) = @_;
    
    unless (defined $self->etab->{$string}) {
        $self->enum($self->enum + 1);
        $self->etab->{$string} = $self->enum;
    }

    return $self->etab->{$string}
}

sub find_return_var {
    my ($self) = @_;

    my $name = $self->name;
    my @rets = grep { $_->isa('Bacon::Stmt::Return') } $self->subnodes;
    
    if (scalar @rets == 0 || !defined $rets[0]->expr) {
        die "Kernel '$name' has return type but doesn't return a value.\n";
    }

    my $var = $rets[0]->expr;

    for my $stmt (@rets) {
        my $expr = $stmt->expr;
        
        die "Mismatched return type in kernel '$name' at " . $stmt->source
            unless (defined $expr);

        die "Kernel '$name' must return exactly one variable"
            unless ($expr->name eq $var->name);
    }

    return $var->name;
}

sub init_magic_variables {
    my ($self) = @_;

    my @vars = grep { 
        $_->isa('Bacon::Expr::Identifier') 
    } $self->subnodes;

    my %seen = ();

    for my $var (@vars) {
        $seen{$var->name} = 1;
    }

    my $code = '';

    if ($seen{'$x'}) {
        $code .= indent(1);
        $code .= "int _bacon__Sx = get_global_id(0);\n";
    }
    
    if ($seen{'$y'}) {
        $code .= indent(1);
        $code .= "int _bacon__Sy = get_global_id(1);\n";
    }
    
    if ($seen{'$z'}) {
        $code .= indent(1);
        $code .= "int _bacon__Sz = get_global_id(2);\n";
    }

    return $code;
}

sub expanded_args {
    my ($self) = @_;
    my @args = @{$self->args};
    my @retv = grep { $_->retv} values %{$self->vtab};
    die "Can't have multiple return values" if (scalar @retv > 1);
    return map { $_->expand } (@retv, @args);
}

sub local_vars {
    my ($self) = @_;
    return grep { $_->isa('Bacon::Stmt::VarDecl') && !$_->retv } 
        values %{$self->vtab};
}

sub init_array_structs {
    my ($self) = @_;
    my @args = grep { !$_->isa('Bacon::Stmt::VarDecl') || $_->retv } 
        values %{$self->vtab};

    my $code = "";

    for my $arg (@args) {
        next unless $arg->ptype;
        $code .= $arg->init_struct;
    }

    return $code;
}

sub to_opencl {
    my ($self, $pgm) = @_;
    assert_type($pgm, "Bacon::Program");

    my $code = "/* Kernel: " . $self->name . 
               " " . $self->source . " */\n";

    my @dims = map { $_->to_ocl($self) } @{$self->dist};
    $code .= "kernel void\n";
    $code .= "/* returns: " . $self->retv . "\n";
    $code .= " * distrib: ";
    $code .= " [" . join(', ', @dims) . "]\n";
    $code .= " */\n";

    if ($self->retv ne 'void') {
        my $vname = $self->find_return_var;
        $self->vtab->{$vname}->retv(1);
    }
 
    my @args = $self->expanded_args;

    $code .= $self->name . "(";
    $code .= join(', ', map { $_->decl_fun_arg($self) } @args);
    $code .= ", global long* _bacon__status)\n";

    $code .= "{\n";

    $code .= $self->init_magic_variables;

    $code .= $self->init_array_structs;
    
    my @vars = $self->local_vars;
    for my $var (@vars) {
        $code .= $var->decl_to_opencl($self, 1);
    }

    $code .= $self->body->contents_to_opencl($self, 0);

    $code .= "}\n\n";

    return $code;
}

sub wrapper_args {
    my ($self) = @_;
    my @args = map { $_->to_wrapper_hh } @{$self->args};
    return @args;
}

sub to_wrapper_hh {
    my ($self) = @_;
    return indent(1)
        . cpp_header_type($self->retv) . " "
        . $self->name
        . '('
        . join(', ', $self->wrapper_args)
        . ");\n";
}

sub wrapper_range {
    my ($self) = @_;
    return join(', ', map { $_->to_cpp($self) } (reverse @{$self->dist}));
}

sub decl_return_var {
    my ($self) = @_;
    my $type = cpp_type($self->retv);
    my $name = $self->find_return_var;
    my $retv = $self->vtab->{$name};
    my $dims = $retv->cpp_dims($self);
    return (
        "$type $name($dims);",
        "$name.set_context(&ctx);"
    );
}

sub wrapper_body {
    my ($self) = @_;
    my $name  = $self->name;
    my @lines = ();

    unless ($self->retv eq 'void') {
        push @lines, $self->decl_return_var;
        push @lines, ''; 
    }
    
    for my $arg (@{$self->args}) {
        if ($arg->type =~ /\<.*\>/) {
            push @lines, $arg->name . ".set_context(&ctx);";
        }
    }

    push @lines, ''; 

    push @lines, 'Bacon::Array<cl_long> status(2);';
    push @lines, 'status.fill(0);';
    push @lines, 'status.set_context(&ctx);';

    push @lines, ''; 

    push @lines, qq{Kernel kern(ctx.pgm, "$name");};
    
    push @lines, '';
   
    my $argn = 0;
    my @args = $self->expanded_args;

    for my $arg (@args) {
        my $arg_name = $arg->cc_name;
        push @lines, "kern.setArg($argn, $arg_name);";
        $argn++;
    }

    push @lines, "kern.setArg($argn, status.data());";
    push @lines, '';

    my $range = $self->wrapper_range;
    push @lines, qq{NDRange range($range);};

    push @lines, 'Event done;';
    push @lines, 'ctx.queue.enqueueNDRangeKernel('
        . 'kern, NullRange, range, NullRange, 0, &done);';
    push @lines, 'done.wait();';

    push @lines, '';

    push @lines, 'if (status.get(0)) {';
    push @lines, $self->error_code_switch;
    push @lines, '}';

    unless ($self->retv eq 'void') {
        my $rv_name = $self->find_return_var;
        push @lines, "return $rv_name;";
    }

    return @lines;
}

sub error_code_switch {
    my ($self) = @_;
    my @lines = 'switch (status.get(0)) {';

    for my $string (keys %{$self->etab}) {
        my $err_no = $self->etab->{$string};
        push @lines, qq{  case $err_no: throw Bacon::Error("$string", status.get(1));};
    }

    push @lines, '  default: throw Bacon::Error("Unknown Error", status.get(1));';
    push @lines, '}';

    return map { "    " . $_ } @lines;
}

sub to_wrapper_cc {
    my ($self) = @_;
    my $class = $self->basefn;
    my $name  = $self->name;
    return cpp_type($self->retv) . "\n"
        . $class . "::" . $name
        . '('
        . join(', ', $self->wrapper_args)
        . ")\n{\n"
        . indent(1) . "try {\n"
        . join("\n", map { indent(2) . $_ } $self->wrapper_body) . "\n"
        . indent(1) . "}\n"
        . indent(1) . "catch (cl::Error ee) {\n"
        . indent(2) . "std::ostringstream tmp;\n"
        . indent(2) . 'tmp << "OpenCL Error: ";' . "\n"
        . indent(2) . "tmp << cl_strerror(ee.err());\n"
        . indent(2) . "throw Bacon::Error(tmp.str());\n"
        . indent(1) . "}\n"
        . "\n}\n\n";
}

__PACKAGE__->meta->make_immutable;
1;
