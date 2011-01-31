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

extern unsigned long BaseBuffer_random_seed;

template <class NumT>
class BaseBuffer {
  public:
    BaseBuffer()
        : data_size(0), on_gpu(false), ctx(0)
    {
        srandom(getpid() * BaseBuffer_random_seed);
        BaseBuffer_random_seed *= random();
    }

    BaseBuffer(cl_uint nn) 
        : data_size(nn), on_gpu(false), ctx(0)
    {
        reallocate(nn);
    }

    ~BaseBuffer()
    {
        // do nothing
    }

    void reallocate(int nn)
    {
        data_size = nn;
        data_ptr = boost::shared_array<NumT>(new NumT[nn]);
        on_gpu = false;
    }

    void set_context(Bacon::Context* context)
    {
        ctx = context;

        cl_mem_flags flags = 0;
        buffer = cl::Buffer::Buffer(ctx->ctx, flags, byte_size());
    }

    void fill(NumT vv)
    {
        for(int ii = 0; ii < size(); ++ii)
            data_ptr[ii] = vv;
        on_gpu = false;
    }

    void fill_random()
    {
        for(int ii = 0; ii < size(); ++ii)
            data_ptr[ii] = (NumT)(random() % 100);
        on_gpu = false;        
    }

    cl::Buffer data()
    {
        if (!on_gpu)
            send_dev();
        return buffer;
    }

    NumT get(cl_uint xx)
    {
        if (on_gpu)
            recv_dev();
        return data_ptr[xx];
    }

    void set(cl_uint xx, NumT vv)
    {
        if (on_gpu)
            recv_dev();
        data_ptr[xx] = vv;
    }

    void send_dev()
    {
        assert(ctx != 0);
        ctx->queue.enqueueWriteBuffer(buffer, true, 0, byte_size(), data_ptr.get());
        on_gpu = true;
    }

    void recv_dev()
    {
        assert(ctx != 0);
        ctx->queue.enqueueReadBuffer(buffer, true, 0, byte_size(), data_ptr.get());
        on_gpu = false;
    }

    size_t byte_size()
    {
        return size() * sizeof(NumT);
    }

    void read_items(std::istream* in_file)
    {
        for (int ii = 0; ii < size(); ++ii) {
            *in_file >> data_ptr[ii];
        }
        
        on_gpu = false;
    }

    void write_items(std::ostream* out_file)
    {
        if (on_gpu)
            recv_dev();

        for (int ii = 0; ii < size(); ++ii) {
            *out_file << data_ptr[ii] << " ";
        }

        *out_file << std::endl;
    }

    virtual void write(std::ostream*) = 0;
    virtual void read(std::istream*) = 0;

    cl_uint size() const
    {
        return data_size;
    }

 protected:
    cl_uint data_size;

    bool on_gpu;

    Bacon::Context* ctx;
    cl::Buffer buffer;
    boost::shared_array<NumT> data_ptr;

};

template <class NumT>
bool 
operator==(BaseBuffer<NumT>& aa, BaseBuffer<NumT>& bb)
{
    if (aa.size() != bb.size())
        return false;
    
    for (int ii = 0; ii < aa.size(); ++ii) {
        if (aa.get(ii) != bb.get(ii))
                return false;
    }
    
    return true;
}


template <class NumT>
class Array : public BaseBuffer<NumT> {
  public:
    Array()
        : BaseBuffer<NumT>()
    {
        // do nothing
    }

    Array(cl_uint nn)
        : BaseBuffer<NumT>(nn)
    {
        // do nothing
    }

    NumT get(cl_uint xx)
    {
        return BaseBuffer<NumT>::get(xx);
    }

    void set(cl_uint xx, NumT vv)
    {
        BaseBuffer<NumT>::set(xx, vv);
    }

    void read(std::istream* in_file)
    {
        cl_uint nn;
        *in_file >> nn;

        BaseBuffer<NumT>::reallocate(nn);
        BaseBuffer<NumT>::read_items(in_file);
    }

    void write(std::ostream* out_file)
    {
        *out_file << cols() << "\n";

        for (int jj = 0; jj < cols(); ++jj) {
            *out_file << get(jj) << " ";
        }
        *out_file << "\n";
    }    

    cl_uint cols() const
    {
        return BaseBuffer<NumT>::data_size;
    }
};

template <class NumT>
class Array2D : public BaseBuffer<NumT> {
  public:
    Array2D()
        : data_rows(0), data_cols(0), BaseBuffer<NumT>()
    {
        // do nothing
    }

    Array2D(cl_uint yy, cl_uint xx) 
        : data_rows(yy), data_cols(xx), BaseBuffer<NumT>(yy*xx)
    {
        // do nothing
    }

    NumT get(cl_uint yy, cl_uint xx)
    {
        return BaseBuffer<NumT>::get(yy * cols() + xx);
    }

    void set(cl_uint yy, cl_uint xx, NumT vv)
    {
        return BaseBuffer<NumT>::set(yy * cols() + xx, vv);
    }

    void fill_identity_matrix()
    {
        for (int ii = 0; ii < rows(); ++ii) {
            for (int jj = 0; jj < cols(); ++jj) {
                set(ii, jj, (NumT)(ii == jj ? 1 : 0));
            }
        }
    }

    void read(std::istream* in_file)
    {
        *in_file >> data_rows;
        *in_file >> data_cols;

        BaseBuffer<NumT>::reallocate(data_rows * data_cols);
        BaseBuffer<NumT>::read_items(in_file);
    }

    void write(std::ostream* out_file)
    {
        *out_file << rows() << " ";
        *out_file << cols() << "\n";

        for (int ii = 0; ii < rows(); ++ii) {
            for (int jj = 0; jj < cols(); ++jj) {
                *out_file << get(ii, jj) << " ";
            }
            * out_file << "\n";
        }
    }

    cl_uint rows() const
    {
        return data_rows;
    }

    cl_uint cols() const
    {
        return data_cols;
    }

  private:
    cl_uint data_rows;
    cl_uint data_cols;
};

template <class NumT>
bool 
operator==(Array2D<NumT>& aa, Array2D<NumT>& bb)
{
    if (aa.size() != bb.size() || aa.rows() != bb.rows() || aa.cols() != bb.cols())
        return false;

    for (int ii = 0; ii < aa.rows(); ++ii) {
        for (int jj = 0; jj < aa.cols(); ++jj) {
            if (aa.get(ii, jj) != bb.get(ii, jj))
                return false;
        }
    }
    
    return true;
}


template <class NumT>
class Array3D : public BaseBuffer<NumT> {
  public:
    Array3D(cl_uint zz, cl_uint yy, cl_uint xx) 
        : data_deep(zz), data_rows(yy), data_cols(xx), BaseBuffer<NumT>(zz*yy*xx)
    {
        // do nothing
    }

    NumT get(int zz, int yy, int xx)
    {
        return BaseBuffer<NumT>::get(zz * rows() * cols() + yy * cols() + xx);
    }

    cl_uint deep() 
    {
        return data_deep;
    }

    cl_uint rows()
    {
        return data_rows;
    }

    cl_uint cols()
    {
        return data_cols;
    }

  private:
    cl_uint data_deep;
    cl_uint data_rows;
    cl_uint data_cols;
};

} // namespace Bacon
#endif
