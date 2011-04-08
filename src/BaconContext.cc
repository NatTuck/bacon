
#include <utility>
using std::make_pair;

#include <sstream>
#include <fstream>
#include <iostream>
using std::cout;
using std::cerr;
using std::endl;

#include <Bacon.hh>
using namespace cl;

#include "cl_perror.hh"

namespace Bacon {

unsigned long Bacon_Array_random_seed = 65537;
bool use_opencl_cpu = false;

void
context_error_callback(const char* msg, const void* extra_data, 
        std::size_t extra_size, void* context)
{
    cerr << "Got OpenCL Error: " << msg << endl;
    exit(1);
}

Context::Context()
{
    show_timing = false;

    dev = best_opencl_device();

    std::vector<cl::Device> devs;
    devs.push_back(dev);
    ctx = cl::Context(devs, 0, context_error_callback, this);

    queue = CommandQueue(ctx, dev);
}

Context::~Context()
{
    // do nothing
}



cl::Device
Context::best_opencl_device()
{
    std::vector<Platform> platforms;
    Platform::get(&platforms);

    std::vector<Device> devs;
    std::vector<Platform>::iterator pit;

    cl_device_type preferred_type = CL_DEVICE_TYPE_GPU;

    if (use_opencl_cpu) {
        preferred_type = CL_DEVICE_TYPE_CPU;
    }

    // First, try to find a GPU
    for (pit = platforms.begin(); pit != platforms.end(); ++pit) {
        try {
            pit->getDevices(preferred_type, &devs);
        }
        catch (cl::Error ee) {
            if (ee.err() != CL_DEVICE_NOT_FOUND)
                throw(ee);
        }

        if (devs.size()) {
            // Found a GPU, done.
            return devs.at(0);
        }
    }

    // If we can't find a GPU, take what we can get.
    for (pit = platforms.begin(); pit != platforms.end(); ++pit) {
        try {
            pit->getDevices(CL_DEVICE_TYPE_ALL, &devs);
        }
        catch (cl::Error ee) {
            if (ee.err() != CL_DEVICE_NOT_FOUND)
                throw(ee);
        }

        if (devs.size()) {
            return devs.at(0);
        }
    }

    // If we can't find any OpenCL devices, that's a problem.
    cerr << "No valid OpenCL devices found." << endl;
    exit(1);
}

cl::Program
Context::load_opencl_program(std::string src_fn)
{
    // OpenCL wants a vector of (char*, length) pairs, but doesn't
    // take any ownership of the pointers.

    cl::Program pgm;

    // First, read the file into one std::string.

    std::ifstream source_stream(src_fn.c_str());

    std::ostringstream build;
    std::string line;

    while (source_stream.good()) {
        getline(source_stream, line);
        build << line << "\n";
    }

    build << "\n\n";
    std::string pgm_src = build.str();

    if (pgm_src.empty()) {
        cerr << "Epic fail" << endl;
        exit(1);
    }

    // Now, the (ptr, length) pairs we need are just
    // pointers into that string's data buffer.

    const char* source_ptr = pgm_src.c_str();

    Program::Sources src_lines;
    
    const char* start = source_ptr;
    std::size_t length = 0;
    const char* ii = source_ptr;

    while (true) {
        if (*ii == '\n') {
            src_lines.push_back(make_pair(start, length + 1));
            start  = ii + 1;
            length = 0;
        } else {
            ++length;
        }

        if (*ii == '\0')
            break;
        else
            ++ii;
    }

    pgm = Program(ctx, src_lines);
    std::vector<Device> devs;
    devs.push_back(dev);

    // Now for the fun part, where we figure out the compiler
    // options.
    //
    // TODO: Allow user to disable aggressive math-altering
    // optimizations.
    std::string opts("-I gen/ocl -cl-strict-aliasing -cl-mad-enable -cl-fast-relaxed-math");

    try {
        pgm.build(devs, opts.c_str());
    } 
    catch (cl::Error ee) {
        if (cl_strerror(ee.err()) == "CL_BUILD_PROGRAM_FAILURE") {
            cerr << "Error building OpenCL kernels." << endl;
            cerr << endl;

            std::string build_log = pgm.getBuildInfo<CL_PROGRAM_BUILD_LOG>(dev);
            cerr << build_log << endl;
        }
        exit(1);
    }

    return pgm;
}

} // namespace Bacon
