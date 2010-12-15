
namespace Bacon {

#include "gen/BaconContext.hh"
using namespace cl;

void
context_error_callback(const char* msg, const void* extra_data, 
        std::size_t extra_size, void* context)
{
    cerr << "Got OpenCL Error: " << msg << endl;
    exit(1);
}

Context::Context()
{
    dev = find_best_device();

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

    // First, try to find a GPU
    for (pit = platforms.begin(); pit != platforms.end(); ++pit) {
        try {
            pit->getDevices(CL_DEVICE_TYPE_GPU, &devs);
            //pit->getDevices(CL_DEVICE_TYPE_CPU, &devs);
        }
        catch (Error ee) {
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
        catch (Error ee) {
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

void
Context::load_opencl_program(std::string src_fn)
{
    // OpenCL wants a vector of (char*, length) pairs, but doesn't
    // take any ownership of the pointers.

    // First, read the file into one std::string.

    std::ifstream source_stream(src_fn.c_str());

    std::ostringstream build;
    std::string line;

    while (source_stream.good()) {
        getline(source_stream, line);
        build << line << "\n";
    }

    build << "\n\n";
    pgm_src = build.str();

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

    try {
        pgm.build(devs);    
    } 
    catch (Error ee) {
        if (cl_strerror(ee.err()) == "CL_BUILD_PROGRAM_FAILURE") {
            cerr << "Error building OpenCL kernels." << endl;
            cerr << endl;

            std::string build_log = pgm.getBuildInfo<CL_PROGRAM_BUILD_LOG>(dev);
            cerr << build_log << endl;
        }
        exit(1);
    }
}

} // namespace Bacon
