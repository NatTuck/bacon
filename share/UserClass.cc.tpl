
/* This file is auto-generated. */

/* Don't make changes here, they're likely to mysteriously vanish. */

#include <sstream>

#include "cl_perror.hh"
#include "BaconError.hh"

#include "<% $name %>.hh"

using namespace Bacon;
using namespace cl;

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
