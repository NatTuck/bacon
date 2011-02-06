#ifndef BACON_CONTEXT_HH
#define BACON_CONTEXT_HH

#define __CL_ENABLE_EXCEPTIONS 1
#include <CL/cl.hpp>

namespace Bacon {

class Context {
  public:
    Context();
    ~Context();

    void load_opencl_program(std::string src_fn);

    cl::Device best_opencl_device();

    cl::Device dev;
    cl::Context ctx;
    cl::Program pgm;
    cl::CommandQueue queue;

    bool show_timing;
};

} // namespace Bacon
#endif
