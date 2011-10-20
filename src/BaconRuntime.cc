
#include <sstream>
#include <string>

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

/* this stuff makes Perl do dynamic loading */
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

EXTERN_C void
xs_init(pTHX)
{
    char *file = strdupa(__FILE__);
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

Runtime::Runtime()
{
    int    argc = 1;
    char** argv = sa_alloc(3, "", "-e", "0");
    char** env  = sa_alloc(2, "", "");

    PERL_SYS_INIT3(&argc, &argv, &env);
    my_perl = perl_alloc();
    perl_construct(my_perl);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    perl_parse(my_perl, xs_init, 3, argv, 0);
    //sa_alloc(3);
    perl_run(my_perl);
    perl_use("Bacon::Generate");
}

Runtime::~Runtime()
{
    perl_destruct(my_perl);
    perl_free(my_perl);
    PERL_SYS_TERM();
}

void
Runtime::perl_apply(char* name, char** argv)
{
    static char* ZERO = { 0 };
    if (argv == 0)
        argv = &ZERO;
    call_argv(name, G_VOID | G_DISCARD, argv);
}

void
Runtime::perl_eval(char* perl_code)
{
    std::ostringstream code;
    code << "use 5.10.0;";
    code << perl_code;
    eval_pv(code.str().c_str(), TRUE);
}

void
Runtime::perl_use(const char* module)
{
    SV* mod_name = newSVpv(module, 0);
    load_module(0, mod_name, 0, 0);
    //sv_free(mod_name);
}

} // namespace Bacon
