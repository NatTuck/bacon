
/* This file is auto-generated. */

/* Don't make changes here, they're likely to mysteriously vanish. */

#include "gen/<% $name %>.hh"

// Constructor
<% $name %>::<% $name %>()
{
    ctx.load_opencl_program("gen/<% $name %>.cl");
}

// Destructor
<% $name %>::~<% $name %>()
{
    // do nothing
}

<% $functions %>
