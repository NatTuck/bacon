#ifndef BACON_ARRAY_HH
#define BACON_ARRAY_HH

#include <cassert>
#include <fstream>
#include <sstream>
#include <iostream>
using std::cout;
using std::endl;

#define __CL_ENABLE_EXCEPTIONS 1
#include <CL/cl.hpp>

#include <boost/shared_array.hpp>
#include <boost/shared_ptr.hpp>

#include <Bacon/Context.hh>

namespace Bacon {

extern unsigned long Bacon_Array_random_seed;

template <class NumT>
class Array {
  public:
    Array()
        : data_size(0), on_gpu(false), ctx(0)
    {
        srandom(getpid() * Bacon_Array_random_seed);
        Bacon_Array_random_seed *= random();
    }

    Array(cl_uint nn) 
        : data_size(nn), on_gpu(false), ctx(0)
    {
        reallocate(nn);
    }

    ~Array()
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
        if (ctx != context) {
            ctx = context;

            cl_mem_flags flags = 0;
            buffer = cl::Buffer::Buffer(ctx->ctx, flags, byte_size());
        }
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

    NumT* ptr()
    {
        if (on_gpu)
            recv_dev();
        return data_ptr.get();
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

    cl_uint size() const
    {
        return data_size;
    }

    void read(std::istream* in_file)
    {
        cl_uint nn;
        *in_file >> nn;

        reallocate(nn);
        read_items(in_file);
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
operator==(Array<NumT>& aa, Array<NumT>& bb)
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
class Array2D : public Array<NumT> {
  public:
    Array2D()
        : data_rows(0), data_cols(0), Array<NumT>()
    {
        // do nothing
    }

    Array2D(cl_uint yy, cl_uint xx) 
        : data_rows(yy), data_cols(xx), Array<NumT>(yy*xx)
    {
        // do nothing
    }

    NumT get(cl_uint yy, cl_uint xx)
    {
        return Array<NumT>::get(yy * cols() + xx);
    }

    void set(cl_uint yy, cl_uint xx, NumT vv)
    {
        return Array<NumT>::set(yy * cols() + xx, vv);
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

        Array<NumT>::reallocate(data_rows * data_cols);
        Array<NumT>::read_items(in_file);
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
class Array3D : public Array<NumT> {
  public:
    Array3D(cl_uint zz, cl_uint yy, cl_uint xx) 
        : data_deep(zz), data_rows(yy), data_cols(xx), Array<NumT>(zz*yy*xx)
    {
        // do nothing
    }

    NumT get(int zz, int yy, int xx)
    {
        return Array<NumT>::get(zz * rows() * cols() + yy * cols() + xx);
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

    void read(std::istream* in_file)
    {
        *in_file >> data_deep;
        *in_file >> data_rows;
        *in_file >> data_cols;

        Array<NumT>::reallocate(data_rows * data_cols);
        Array<NumT>::read_items(in_file);
    }

    void write(std::ostream* out_file)
    {
        *out_file << deep() << " ";
        *out_file << rows() << " ";
        *out_file << cols() << "\n";

        for (int kk = 0; kk < deep(); ++kk) {
            for (int ii = 0; ii < rows(); ++ii) {
                for (int jj = 0; jj < cols(); ++jj) {
                    *out_file << get(kk, ii, jj) << " ";
                }
                *out_file << "\n";
            }
            *out_file << "\n";
        }
    }

  private:
    cl_uint data_deep;
    cl_uint data_rows;
    cl_uint data_cols;
};

template <class NumT>
bool 
operator==(Array3D<NumT>& aa, Array3D<NumT>& bb)
{
    if (aa.size() != bb.size() || aa.rows() != bb.rows()
        || aa.cols() != bb.cols() || aa.deep() != bb.deep())
        return false;

    for (int ii = 0; ii < aa.rows(); ++ii) {
        for (int jj = 0; jj < aa.cols(); ++jj) {
            for (int kk = 0; kk < aa.deep(); ++kk) {
                if (aa.get(ii, jj, kk) != bb.get(ii, jj, kk))
                    return false;
            }
        }
    }
    
    return true;
}


} // namespace Bacon
#endif
