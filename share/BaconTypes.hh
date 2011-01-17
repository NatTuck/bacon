#ifndef BACON_TYPES_HH
#define BACON_TYPES_HH

#include <cassert>
#include <iostream>
#include <fstream>
#include <sstream>

#define __CL_ENABLE_EXCEPTIONS 1
#include <CL/cl.hpp>

#include <boost/shared_array.hpp>
#include <boost/shared_ptr.hpp>

#include "BaconContext.hh"

namespace Bacon {

template <class NumT>
class BaseBuffer {
  public:
    BaseBuffer(cl_uint xx) 
        : size(xx), on_gpu(false), ctx(0)
    {
        data = boost::shared_array<NumT>(new NumT[size]);
    }

    ~BaseBuffer()
    {
        // do nothing
    }

    void set_context(Bacon::Context* context)
    {
        ctx = context;

        cl_mem_flags flags = 0;
        buffer = cl::Buffer::Buffer(ctx->ctx, flags, byte_size());
    }

    void fill(NumT vv)
    {
        for(int ii = 0; ii < size; ++ii)
            data[ii] = vv;
        on_gpu = false;
    }

    cl::Buffer get_buffer()
    {
        if (!on_gpu)
            send_dev();
        return buffer;
    }

    NumT* get_data()
    {
        if (on_gpu)
            recv_dev();
        return data;
    }

    NumT get(cl_uint xx)
    {
        if (on_gpu)
            recv_dev();
        return data[xx];
    }

    void send_dev()
    {
        assert(ctx != 0);
        ctx->queue.enqueueWriteBuffer(buffer, true, 0, byte_size(), data.get());
        on_gpu = true;
    }

    void recv_dev()
    {
        assert(ctx != 0);
        ctx->queue.enqueueReadBuffer(buffer, true, 0, byte_size(), data.get());
        on_gpu = false;
    }

    size_t byte_size()
    {
        return size * sizeof(NumT);
    }

    void read_items(std::istream& in_file)
    {
        for (int ii = 0; ii < size; ++ii) {
            in_file >> data[ii];
        }
        
        on_gpu = false;
    }

    void write_items(std::ostream& out_file)
    {
        if (on_gpu)
            recv_dev();

        for (int ii = 0; ii < size; ++ii) {
            out_file << data[ii];
        }
    }

    void read(std::ostream&);
    void write(std::istream&);

    void read(std::string fname)
    {
        std::ifstream in_file(fname);
        read(in_file);
    }

    void write(std::string fname)
    {
        std::ofstream out_file(fname);
        write(out_file);
    }
    
    const cl_uint size;

  private:
    bool on_gpu;

    Bacon::Context* ctx;
    cl::Buffer buffer;
    boost::shared_array<NumT> data;
};

template <class NumT>
class Array2D : public BaseBuffer<NumT> {
  public:
    Array2D(cl_uint yy, cl_uint xx) 
        : rows(yy), cols(xx), BaseBuffer<NumT>(yy*xx)
    {
        // do nothing
    }

    static Array2D<NumT> new_from_stream(std::ifstream in_file)
    {
        int rows, cols;
        in_file >> rows;
        in_file >> cols;

        Array2D<NumT> aa(rows, cols);
        aa.read_items(in_file);

        return aa;
    }

    NumT get(cl_uint yy, cl_uint xx)
    {
        return BaseBuffer<NumT>::get(yy*cols + xx);
    }

    void write(std::ostream& out_file)
    {
        out_file << rows;
        out_file << cols;

        BaseBuffer<NumT>::write_items(out_file);
    }

    void read(std::istream& in_file)
    {
        long rr, cc;

        in_file >> rr; rows = (cl_uint) rr;
        in_file >> cc; cols = (cl_uint) cc;

        BaseBuffer<NumT>::read_items(in_file);
    }

    std::string to_string()
    {
        std::ostringstream out_string;
        write(out_string);
        return out_string.str();
    }

    const cl_uint rows;
    const cl_uint cols;
};

template <class NumT>
class Array3D : public BaseBuffer<NumT> {
  public:
    Array3D(cl_uint zz, cl_uint yy, cl_uint xx) 
        : deep(zz), rows(yy), cols(xx), BaseBuffer<NumT>(zz*yy*xx)
    {
        // do nothing
    }

    const cl_uint deep;
    const cl_uint rows;
    const cl_uint cols;
};

} // namespace Bacon
#endif
