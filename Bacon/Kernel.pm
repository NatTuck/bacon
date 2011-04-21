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


has outer_vars => (is => 'ro', isa => 'ArrayRef[Bacon::Stmt::VarDecl]', lazy_build => 1);

# Constants table maps constant variables to their compile-time values.
has const_vals => (is => 'rw', isa => 'Maybe[HashRef[Int]]');

# Error table maps strings to unique integers.
has etab => (is => 'rw', isa => 'Item', lazy_build => 1);

use Bacon::Utils;
use Bacon::MagicVars;

sub _build_symtab {
    my ($self) = @_;
    my $symtab = Bacon::Function::_build_symtab($self);
    
    $symtab->add_outers(@{$self->outer_vars});

    return $symtab;
}

sub _build_etab {
    my ($self) = @_;
    my @strings = grep { $_->isa('Bacon::Expr::String') } $self->subnodes;
    my $etab = {};

    for (my $ii = 0; $ii < scalar @strings; ++$ii) {
        $etab->{$strings[$ii]->value} = $ii + 1;
    }

    return $etab;
}

sub _build_outer_vars {
    my ($self) = @_;
    my @vars = grep { $_->isa('Bacon::Stmt::VarDecl') } $self->setup->subnodes;
    return \@vars;
}

sub build_const_vals {
    my ($self) = @_;

    my @vars = ();
    push @vars, grep { $_->isa('Bacon::Stmt::VarDecl') } $self->setup->subnodes;
    push @vars, grep { $_->isa('Bacon::Stmt::VarDecl') } $self->body->subnodes;

    my @const_vars = ();
    for my $var (@vars) {
        my $name = $var->name;

        if ($var->has_dims) {

            my @dim_ns = @{$var->type->dims};
            my @dim_vs = @{$var->dims};

            for (my $ii = 0; $ii < scalar @dim_ns; ++$ii) {
                my $nn = $dim_ns[$ii];
                my $vv = $dim_vs[$ii]->static_eval($self);
                $self->const_vals->{"$name.$nn"} = $vv;
            }
        }
        elsif ($var->is_const) {
            $self->const_vals->{$name} = $var->init->static_eval($self);
        }
    }
}

sub get_const {
    my ($self, $var) = @_;
    unless (defined $self->const_vals) {
        confess "No constant values in kernel " . $self->name;
    }

    my $val = $self->const_vals->{$var};
    return $val if (defined $val);
    die "No constant value for $var";
}

sub var_is_const {
    my ($self, $vname) = @_;
    return 0 unless defined $self->symtab->table->{$vname};
    return $self->lookup_variable($vname)->is_const;
}

sub const_args {
    my ($self) = @_;
    my @cargs = ();

    my @args = @{$self->args};
    push @args, grep { $_->isa('Bacon::Stmt::VarDecl') } $self->setup->subnodes;

    for my $arg (@args) {
        if ($arg->is_const) {
            push @cargs, $arg->name;
        }
        elsif ($arg->has_dims) {
            for my $dim (@{$arg->type->dims}) {
                push @cargs, $arg->name . '.' . $dim;
            }
        }
    }

    return @cargs;
}

sub const_vars {
    my ($self) = @_;
    my @vars = ();
    push @vars, grep { $_->isa('Bacon::Stmt::VarDecl') } $self->body->subnodes;
    my @cvars = map { $_->name } grep { $_->is_const } @vars;
    return ($self->const_args, @cvars); 
}

sub lookup_error_string {
    my ($self, $string) = @_;
    return $self->etab->{$string} 
        or die "No error code for string: $string";
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

sub expanded_args {
    my ($self) = @_;
    my @vars = (@{$self->args}, @{$self->outer_vars});
    return grep { !$_->is_const } @vars;
}

sub init_array_structs {
    my ($self) = @_;
    my @vars = (@{$self->symtab->args}, @{$self->symtab->outers});

    my $code = "";

    for my $var (@vars) {
        if ($var->has_struct) {
            $code .= $var->init_struct($self);
        }
    }

    return $code;
}

sub to_opencl {
    my ($self, $pgm) = @_;
    assert_type($pgm, "Bacon::Program");
    assert_type($self->rets, "Bacon::Type");

    my $code = "/* Kernel: " . $self->name . 
               " " . $self->source . " */\n";

    my @range_dims = map { $_->to_ocl($self) } @{$self->range};
    my @group_dims = map { $_->to_ocl($self) } @{$self->group};
    $code .= "kernel void\n";
    $code .= "/* returns: " . $self->rets->to_cpp . "\n";
    $code .= " * global distrib range: ";
    $code .= " [" . join(', ', @range_dims) . "]\n";
    $code .= " * work group size: ";
    $code .= " [" . join(', ', @group_dims) . "]\n";
    $code .= " */\n";

    my @args = $self->expanded_args;

    $code .= $self->name . "(";
    $code .= join(', ', map { $_->to_kern_arg($self) } @args);
    $code .= ", global long* _bacon__status)\n";

    $code .= "{\n";

    $code .= $self->init_magic_variables;

    $code .= $self->init_array_structs;
    
    my @vars = $self->symtab_find_local_vars;
    for my $var (@vars) {
        $code .= $var->decl_to_opencl($self, 1);
    }

    $code .= $self->body->contents_to_opencl($self, 1);

    $code .= "}\n\n";

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

sub to_spec_opencl {
    my ($self, $pgm, @const_vals) = @_;
    assert_type($pgm, "Bacon::Program");
    assert_type($self->rets, "Bacon::Type");

    my @const_args = $self->const_args;
    my $spec_text  = "";
    $self->const_vals({});
    for (my $ii = 0; $ii < scalar @const_args; ++$ii) {
        my $vn = $const_args[$ii];
        my $vv = $const_vals[$ii];
        $self->const_vals->{$vn} = $vv;
        $spec_text .= " $vn = $vv; ";
    }

    $self->build_const_vals;

    my $code = "/* Kernel: " . $self->name . 
               " " . $self->source . " */\n";

    my @range_dims = map { $_->to_ocl($self) } @{$self->range};
    my @group_dims = map { $_->to_ocl($self) } @{$self->group};
    $code .= "kernel void\n";
    $code .= "/* returns: " . $self->rets->to_cpp . "\n";
    $code .= " * global distrib range: ";
    $code .= " [" . join(', ', @range_dims) . "]\n";
    $code .= " * work group size: ";
    $code .= " [" . join(', ', @group_dims) . "]\n";
    $code .= " * specialized on:  [ $spec_text ]";
    $code .= " */\n";

    my @args = $self->expanded_args;

    $code .= $self->name . "(";
    $code .= join(', ', map { $_->to_kern_arg($self) } @args);
    $code .= ", global long* _bacon__status)\n";

    $code .= "{\n";

    $code .= $self->init_magic_variables;

    $code .= $self->init_array_structs;
    
    my @vars = $self->symtab_find_local_vars;
    for my $var (@vars) {
        $code .= $var->decl_to_opencl($self, 1);
    }

    $code .= $self->body->contents_to_opencl($self, 1);

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

    my @vars  = $self->symtab->possible_return_vars;

    my @lines = 'switch (status.get(0)) {';
  
    for(my $ii = 0; $ii < (scalar @vars); ++$ii) {
        my $name = $vars[$ii]->name;
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



__[ foo ]__
END_OF_DATA
