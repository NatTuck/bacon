#ifndef BACON_KERNEL_HH
#define BACON_KERNEL_HH

#define __CL_ENABLE_EXCEPTIONS 1
#include <CL/cl.hpp>

#include <vector>
#include <string>
#include <map>

namespace Bacon {

class Kernel {
  public:
    Bacon::Context ctx;
    Bacon::Runtime* rt;

  protected:
    std::string spec_key(std::string kname, std::vector<int> cargs);
    cl::Kernel spec_kernel(std::string bname, std::string kname, std::vector<int> cargs);

    std::map<std::string, cl::Program> pgms;
};

} // namespace Bacon

#endif
