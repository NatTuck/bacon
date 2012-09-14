package Bacon::MagicVars;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Carp;

our %MAGIC_VARS = (
    WORK_DIM    => 'get_work_dim()',
    GLOBAL_COLS => 'get_global_size(0)',
    GLOBAL_ROWS => 'get_global_size(1)',
    GLOBAL_DEPS => 'get_global_size(2)',
    COLS        => 'get_global_size(0)',
    ROWS        => 'get_global_size(1)',
    DEPS        => 'get_global_size(2)',
    global_col  => 'get_global_id(0)',
    global_row  => 'get_global_id(1)',
    global_dep  => 'get_global_id(2)',
    col         => 'get_global_id(0)',
    row         => 'get_global_id(1)',
    dep         => 'get_global_id(2)',
    global_x    => 'get_global_id(0)',
    global_y    => 'get_global_id(1)',
    global_z    => 'get_global_id(2)',
    x           => 'get_global_id(0)',
    y           => 'get_global_id(1)',
    z           => 'get_global_id(2)',
    LOCAL_COLS  => 'get_local_size(0)',
    LOCAL_ROWS  => 'get_local_size(1)',
    LOCAL_DEPS  => 'get_local_size(2)',
    local_col   => 'get_local_id(0)',
    local_row   => 'get_local_id(1)',
    local_dep   => 'get_local_id(2)',
    local_x     => 'get_local_id(0)',
    local_y     => 'get_local_id(1)',
    local_z     => 'get_local_id(2)',
    GROUP_COLS  => 'get_num_groups(0)',
    GROUP_ROWS  => 'get_num_groups(1)',
    GROUP_DEPS  => 'get_num_groups(2)',
    group_col   => 'get_group_id(0)',
    group_row   => 'get_group_id(1)',
    group_dep   => 'get_group_id(2)',
);

sub magic_var_exists {
    my ($name) = @_;
    $name =~ s/^\$//;
    return defined($MAGIC_VARS{$name});
}

sub magic_var_ocl {
    my ($name) = @_;
    $name =~ s/^\$//;
    my $expr = $MAGIC_VARS{$name}
        or confess "No such magic variable: $name";
    return $expr;
}

1;
