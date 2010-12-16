
#include "gen/<% $name %>.hh"

// Constructor
<% $name %>::<% $name %>()
{
    ctx = new Bacon::Context();
    ctx.load_opencl_program("gen/<% $name %>.cl");
}

// Destructor
<% $name %>::~<% $name %>()
{
    // do nothing
}

<% $functions %>
