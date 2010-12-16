#ifndef BACON_<% uc $name %>_HH_GUARD
#ifndef BACON_<% uc $name %>_HH_GUARD

#include <gen/Bacon.hh>

class <% $name %> {
  public:
    <% $name %>();
    ~<% $name %>();

<% $prototypes %>

  private:
    Bacon::Context ctx;
};

#endif
