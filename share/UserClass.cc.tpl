
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

// Constructor
<% $name %>::<% $name %>()
{
    char **argv = sa_alloc(2, "gen/<% $name %>.ast", 0);
    rt = Bacon::Runtime::instance();
    rt->perl_apply(strdupa("bacon_generate_ocl"), argv);
    sa_free(2, argv);

    ctx.load_opencl_program("gen/<% $name %>.cl");
}

using namespace cl;

// Destructor
<% $name %>::~<% $name %>()
{
    // do nothing
}

<% $functions %>
