#ifndef BACON_CONTEXT_HH
#define BACON_CONTEXT_HH

#define __CL_ENABLE_EXCEPTIONS 1
#include <CL/cl.hpp>

namespace Bacon {

extern bool use_opencl_cpu;

class Context {
  public:
    Context();
    ~Context();

    cl::Device best_opencl_device();
    cl::Program load_opencl_program(std::string src_fn);

    cl::Device dev;
    cl::Context ctx;
    cl::CommandQueue queue;

    bool show_timing;
};

} // namespace Bacon
#endif
