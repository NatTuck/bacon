
#include "Bacon/Runtime.hh"

#include <EXTERN.h>
#include <perl.h>

namespace Bacon {

static Runtime *Bacon_Runtime_instance = 0;
static PerlInterpreter *my_perl;

Runtime*
Runtime::instance()
{
    if (!Bacon_Runtime_instance) {
        Bacon_Runtime_instance = new Bacon::Runtime;
    }

    return Bacon_Runtime_instance;
}

Runtime::Runtime()
{
    PERL_SYS_INIT3(0, 0, 0);
    my_perl = perl_alloc();
    perl_construct(my_perl);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
}

Runtime::~Runtime()
{
    perl_destruct(my_perl);
    perl_free(my_perl);
    PERL_SYS_TERM();
}

void
Runtime::load_perl(char* source_fn)
{
    perl_parse(my_perl, 0, 1, &source_fn, 0);
}

} // namespace Bacon
