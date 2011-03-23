#ifndef BACON_RUNTIME_HH
#define BACON_RUNTIME_HH

namespace Bacon {

class Runtime {
  public:
    static Runtime* instance();

    void perl_apply(char* name, char** argv);
    void perl_eval(char* perl_code);
    void perl_use(const char* module);

  private:
    Runtime();
    ~Runtime();
};

} // namespace Bacon

#include <stdarg.h>
#include <string.h>
#include <stdlib.h>

inline char**
sa_alloc(int argc, ...)
{
    char** ptr = new char*[argc];

    va_list ap;
    va_start(ap, argc);

    for (int ii = 0; ii < argc; ++ii) {
        char *ss = va_arg(ap, char *);
        if (ss)
            ptr[ii] = strdup(ss);
        else
            ptr[ii] = 0;
    }

    va_end(ap);

    return ptr;
}

inline void
sa_free(int argc, char** ptr)
{
    for (int ii = 0; ii < argc; ++ii) {
        if (ptr[ii])
            free(ptr[ii]);
    }

    delete[] ptr;
}

#endif
