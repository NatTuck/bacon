
#include <sstream>
#include <string.h>

#include <Bacon.hh>

namespace Bacon {

static std::string
join_ints(std::string sep, std::vector<int> is)
{
    std::ostringstream result;
    if (is.size() == 0)
        return result.str();
    for (int ii = 0; ii < is.size() - 1; ++ii) {
        result << is[ii];
        result << "-";
    }
    result << is[is.size() - 1];
    return result.str(); 
}

std::string
Kernel::spec_key(std::string kname, std::vector<int> cargs)
{
    std::ostringstream kbuf;
    kbuf << kname << ":";
    kbuf << join_ints("-", cargs);
    return kbuf.str();
}

cl::Kernel
Kernel::spec_kernel(std::string bname, std::string kname, std::vector<int> cargs)
{
    std::string key = spec_key(kname, cargs);

    if (pgms.find(key) == pgms.end()) {
        std::ostringstream ast_fn;
        ast_fn << "gen/" << bname << ".ast";

        char **argv = new char*[cargs.size() + 3];
        argv[0] = strdupa(ast_fn.str().c_str());
        argv[1] = strdupa(kname.c_str());
        for (int ii = 0; ii < cargs.size(); ++ii) {
            std::ostringstream itoa;
            itoa << cargs[ii];
            argv[ii + 2] = strdupa(itoa.str().c_str());
        }
        argv[cargs.size() + 2] = 0;

        rt = Bacon::Runtime::instance();
        rt->perl_apply(strdupa("Bacon::Generate::bacon_gen_ocl_kernel"), argv);

        delete[] argv;
        
        std::ostringstream ocl_fn;
        ocl_fn << "gen/" << key << ".cl";
        pgms[key] = ctx.load_opencl_program(strdupa(ocl_fn.str().c_str()));
    }
    
    return cl::Kernel(pgms[key], kname.c_str());
}


} // namespace Bacon
