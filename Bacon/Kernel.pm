package Bacon::Kernel;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
# templates, so no namespace::autoclean

use Data::Dumper;

use Bacon::Function;
use Bacon::Template;
extends 'Bacon::Function', 'Bacon::Template';

has range => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]', required => 1);
has group => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]', required => 1);
has setup => (is => 'ro', isa => 'Bacon::Stmt::Block', required => 1);

# Error table maps strings to unique integers.
has etab => (is => 'rw', isa => 'Item', lazy_build => 1);

use Bacon::Utils;
use Bacon::MagicVars;

sub const_args {
    my ($self) = @_;
    my @cargs = ();

    my @args = @{$self->args};
    push @args, grep { $_->isa('Bacon::Stmt::VarDecl') } $self->setup->subnodes;

    for my $arg (@args) {
        my $var = $self->env->lookup($arg->name);

        if ($var->is_const) {
            push @cargs, $var->name;
        }
        elsif ($var->has_dims) {
            for my $dim (@{$var->type->dims}) {
                push @cargs, $var->name . '.' . $dim;
            }
        }
    }

    return @cargs;
}

after _build_env => sub {
    my ($self) = @_;
    my @rvs = $self->returnable_vars;

    for (my $ii = 0; $ii < scalar @rvs; ++$ii) {
        my $var = $rvs[$ii];
        $var->ridx($ii);
    }
};

sub _build_etab {
    my ($self) = @_;
    my @strings = grep { $_->isa('Bacon::Expr::String') } $self->subnodes;
    my $etab = {};

    for (my $ii = 0; $ii < scalar @strings; ++$ii) {
        $strings[$ii]->idx($ii + 1);
        $etab->{$strings[$ii]->value} = $ii + 1;
    }

    return $etab;
}

sub kids {
    my ($self) = @_;
    return (@{$self->args}, $self->body, $self->setup);
}

sub init_magic_variables {
    my ($self) = @_;
    my $code = '';

    my @vars = grep { $_->isa('Bacon::Expr::Identifier') } $self->subnodes;

    my %seen = ();

    for my $var (@vars) {
        $seen{$var->name} = 1;
    }

    for my $name (keys %seen) {
        if ($name =~ /^\$(\w+)$/) {
            my $cc_name = "_bacon__S$1";
            $code .= indent(1);
            $code .= "int $cc_name = ";
            $code .= Bacon::MagicVars::magic_var_ocl($name);
            $code .= ";\n";
        }
    }

    return $code;
}

sub outer_decls {
    my ($self) = @_;
    return grep { $_->isa('Bacon::Stmt::VarDecl') } $self->setup->subnodes;
}

sub inner_decls {
    my ($self) = @_;
    return grep { $_->isa('Bacon::Stmt::VarDecl') } $self->body->subnodes;
}

sub local_decls {
    my ($self) = @_;
    return ($self->outer_decls, $self->inner_decls);
}

sub expanded_args {
    my ($self) = @_;
    my @args = @{$self->args};
    my @vars =  map { $_->var } $self->outer_decls;
    return grep { !$_->is_const } (@args, @vars);
}

sub returnable_vars {
    my ($self) = @_;
    return grep { 
        $_->type->is_returnable && $_->type->to_cpp eq $self->rets->to_cpp
    } $self->expanded_args;
}

sub init_array_structs {
    my ($self, $env) = @_;
    my @vars = $self->expanded_args;

    my $code = "";

    for my $decl (@vars) {
        my $var = $env->lookup($decl->name);
        if ($var->has_struct) {
            $code .= $var->init_struct($env);
        }
    }

    return $code;
}

sub exclude_vars {
    my (undef, $vars_ref, $excl_ref) = @_;
    my @vars = ();

    my %excl = ();
    for my $vn (@$excl_ref) {
        $vn =~ s/\./__/;
        $excl{$vn} = 1;
        say $vn;
    }

    for my $var (@$vars_ref) {
        next if $excl{$var->name};
        push @vars, $var;
        say $var->name;
    }

    return @vars;
}

sub eval_const_vars {
    my ($self, $env) = @_;
    
    my @decls = $self->local_decls;

    my @const_vars = ();
    for my $decl (@decls) {
        my $var  = $env->lookup($decl->name);
        my $name = $var->name;
        
        if ($var->has_dims) {
            my @dim_ns = @{$var->type->dims};
            my @dim_vs = @{$decl->dims};
            
            for (my $ii = 0; $ii < scalar @dim_ns; ++$ii) {
                my $nn = $dim_ns[$ii];
                my $vv = $dim_vs[$ii]->static_eval($env);
                $env->lookup("$name.$nn")->value($vv);
            }
        }
        elsif ($var->is_const) {
            my $value = $decl->init->static_eval($env);
            $var->value($value);
        }
    }
}

sub list_to_text {
    my ($self, $env, @xs) = @_;
    my @ys = ();
    for my $xx (@xs) {
        push @ys, $xx->to_ocl($env);
    }
    return join(', ', @ys);
}

sub to_spec_opencl {
    my ($self, $pgm, @const_vals) = @_;
    assert_type($pgm, "Bacon::Program");
    assert_type($self->rets, "Bacon::Type");
    $self->etab or die;

    my @const_args = $self->const_args;
    my $spec_text  = "";

    my %const_vals = ();

    for (my $ii = 0; $ii < scalar @const_args; ++$ii) {
        my $vn = $const_args[$ii];
        my $vv = $const_vals[$ii];
        $const_vals{$vn} = $vv;
        $spec_text .= " $vn = $vv; ";
    }

    my $env = $self->env->update_with(%const_vals);
    $self->eval_const_vars($env);

    my @args = $self->expanded_args;
    my $arg_list = join(', ', map { $_->to_kern_arg($self) } @args);

    my @vars = $self->inner_decls;
    my $decl_locals = '';
    for my $var (@vars) {
        $decl_locals .= $var->decl_to_opencl($env, 1);
    }

    return $self->fill_section(
        spec_opencl => 0,
        name        => $self->name,
        source      => $self->source,
        rets        => $self->rets->to_cpp,
        body        => $self->body->contents_to_opencl($env, 1),
        init_magic  => $self->init_magic_variables,
        init_array  => $self->init_array_structs($env),
        self        => $self,
        range       => $self->list_to_text($env, @{$self->range}),
        group       => $self->list_to_text($env, @{$self->group}),
        spec_text   => $spec_text,
        arg_list    => $arg_list,
        decl_locals => $decl_locals,
    );
}

sub wrapper_args {
    my ($self) = @_;
    my @args = map { $_->to_wrapper_hh } @{$self->args};
    return @args;
}

sub to_wrapper_hh {
    my ($self) = @_;
    my $return_type = $self->rets->to_cpp;
    $return_type =~ s/&$//;

    return indent(1)
        . $return_type . " "
        . $self->name
        . '('
        . join(', ', $self->wrapper_args)
        . ");\n";
}

sub wrapper_range {
    my ($self) = @_;
    return join(', ', map { $_->to_cpp($self) } (reverse @{$self->range}));
}

sub local_range {
    my ($self) = @_;
    my $range = join(', ', map { $_->to_cpp($self) } (reverse @{$self->group}));
    if ($range) {
        return "NDRange($range)";
    }
    else {
        return "NullRange";
    }
}

sub join_lines {
    my ($depth, @lines) = @_;
    return "" unless (scalar @lines > 0);

    my $code = shift @lines;
    $code .= "\n";
    
    for my $line (@lines) {
        $code .= indent($depth) . $line . "\n";
    }
    
    return $code;
}

sub to_setup_cc {
    my ($self) = @_;
    my $name  = $self->name;
    my @lines = ();

    for my $stmt (@{$self->setup->body}) {
        push @lines, $stmt->to_setup_cc($self, 0);

        if ($stmt->isa('Bacon::Stmt::VarDecl') && $stmt->dims) {
            push @lines, $stmt->name . ".set_context(&ctx);";
        }
    }

    # TODO: Move arg context elsewhere?
    for my $arg (@{$self->args}) {
        if ($arg->type->isa('Bacon::Type::Array')) {
            push @lines, $arg->name . ".set_context(&ctx);";
        }
    }

    return join_lines(2, @lines);
}

sub push_cargs {
    my ($self) = @_;
    my @args = $self->const_args;
    my @lines = ();

    for (my $ii = 0; $ii < scalar @args; ++$ii) {
        my $name = $args[$ii];
        $name =~ s/$/()/ if $name =~ /\./;
        push @lines, "cargs.push_back($name);";
    }
    
    return join_lines(2, @lines);
}

sub set_args {
    my ($self) = @_;

    my $argn = 0;
    my @lines = ();
    my @args = $self->expanded_args;

    for my $arg (@args) {
        my $arg_name = $arg->cc_name;
        push @lines, "kern.setArg($argn, $arg_name);";
        $argn++;
    }

    return ($argn, join_lines(2, @lines));
}

sub error_code_switch {
    my ($self) = @_;
    my @lines = 'switch (status.get(1)) {';

    for my $string (keys %{$self->etab}) {
        my $err_no = $self->etab->{$string};
        push @lines, qq{    case $err_no: throw Bacon::Error("$string", status.get(2));};
    }

    push @lines, '    default: throw Bacon::Error("Unknown Error", status.get(2));';
    push @lines, '}';

    return join_lines(3, @lines);
}

sub return_stmt_switch {
    my ($self) = @_;
    return "return;" if $self->returns_void;

    my @vars = $self->returnable_vars;

    my @lines = 'switch (status.get(0)) {';
  
    for my $var (@vars) {
        my $name = $var->name;
        my $ii   = $self->env->lookup($name)->ridx;
        push @lines, qq{    case $ii: return $name;};
    }

    push @lines, '    default: throw Bacon::Error("Unknown return var", status.get(0));';
    push @lines, '}';

    return join_lines(2, @lines);
}

sub to_wrapper_cc {
    my ($self) = @_;
    my ($last_argn, $set_args) = $self->set_args;

    my $code = $self->fill_section(
        wrapper_cc  => 0,
        base_name   => $self->basefn,
        push_cargs  => $self->push_cargs,
        return_type => $self->rets->to_cpp,
        class       => $self->basefn,
        kernel_name => $self->name,
        args        => join(', ', $self->wrapper_args),
        setup_code  => $self->to_setup_cc,
        set_args    => $set_args,
        last_argn   => $last_argn,
        nd_range    => $self->wrapper_range,
        local_range => $self->local_range,
        error_cases => $self->error_code_switch,
        ret_stmt    => $self->return_stmt_switch,
    );

    return $code . "\n";
}

__PACKAGE__->meta->make_immutable;
1;

__DATA__
<<"END_OF_DATA";

__[ spec_opencl ]__

/* Kernel: <% $name %> @ <% $source %> */

kernel void
/* returns: <% $rets %>
 * global distrib range: [ <% $range %> ]
 * work group size: [ <% $group %> ]
 * specialized on:  [ <% $spec_text %> ]
 */
<% $name %>(<% $arg_list %>, global long* _bacon__status)
{
    <% $init_magic %>
    <% $init_array %>
    <% $decl_locals %>
    <% $body %>
}

__[ wrapper_cc ]__

<% $return_type %>
<% $class %>::<% $kernel_name %>(<% $args %>)
{
    const char* kernel_name = "<% $kernel_name %>";
    const char* base_name   = "<% $base_name %>";
    cl::Kernel kern;

    try {
        <% $setup_code %>

        std::vector<int> cargs;
        <% $push_cargs %>
        kern = spec_kernel(base_name, kernel_name, cargs);

        Bacon::Array<cl_long> status(3);
        status.fill(0);
        status.set_context(&ctx);

        <% $set_args %>

        kern.setArg(<% $last_argn %>, status.data());

        NDRange range(<% $nd_range %>);

        Bacon::Timer timer;

        Event done;
        ctx.queue.enqueueNDRangeKernel(
            kern, NullRange, range, <% $local_range %>, 0, &done);
        done.wait();

        double kernel_took = timer.time();

        if (status.get(1)) {
            <% $error_cases %>
        }

        if (ctx.show_timing) {
            cout << "Kernel " << kernel_name << " time: " << kernel_took << endl; 
        }

        <% $ret_stmt %>
    }
    catch (cl::Error ee) {
        std::ostringstream tmp;
        tmp << "OpenCL Error (kernel " << kernel_name << "): ";
        tmp << cl_strerror(ee.err());
        throw Bacon::Error(tmp.str());
    }
}

__[ EOF ]__
END_OF_DATA
