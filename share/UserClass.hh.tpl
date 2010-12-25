#ifndef BACON_<% uc $name %>_HH_GUARD
#define BACON_<% uc $name %>_HH_GUARD

/* This file is auto-generated. */

/* Don't make changes here, they're likely to mysteriously vanish. */

#include "Bacon.hh"

class <% $name %> {
  public:
    <% $name %>();
    ~<% $name %>();

<% $prototypes %>

  private:
    Bacon::Context ctx;
};

#endif
