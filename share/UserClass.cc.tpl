
/* This file is auto-generated. */

/* Don't make changes here, they're likely to mysteriously vanish. */

#include <sstream>
#include <iostream>
using std::cout;
using std::endl;

#include <Bacon.hh>

#include "cl_perror.hh"

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
