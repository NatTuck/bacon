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

#if 0
inline
cl_uint
round_to_next(int xx, int nn)
{
    cl_uint rem = xx % nn;
    
    if (rem == 0) {
        return xx;
    }
    else {
        return xx + (nn - rem);
    }
}
#endif

template <class NumT>
class Array {
  public:
    Array()
        : data_size(0), on_gpu(false), valid_data(false)
    {
        ctx = Bacon::Context::get_instance();
        init_random();
    }

    Array(cl_uint nn) 
        : on_gpu(false), valid_data(false)
    {
        ctx = Bacon::Context::get_instance();
        init_random();
        reallocate(nn);
    }

    ~Array()
    {
        // do nothing
    }

    void init_random()
    {
        srandom(getpid() * Bacon_Array_random_seed);
        Bacon_Array_random_seed *= random();
    }

    virtual void
    reallocate(int nn)   
    {
        assert(ctx != 0);
        data_size = nn;
        data_ptr = boost::shared_array<NumT>(new NumT[nn]);
        on_gpu = false;
        valid_data = false;
        buffer = cl::Buffer(ctx->ctx, CL_MEM_USE_HOST_PTR, 
            nn * sizeof(NumT), data_ptr.get());
    }

    void fill(NumT vv)
    {
        for(unsigned int ii = 0; ii < size(); ++ii)
            data_ptr[ii] = vv;
        on_gpu = false;
        valid_data = true;
    }

    void fill_random()
    {
        for(unsigned int ii = 0; ii < size(); ++ii)
            data_ptr[ii] = (NumT)(random() % 100);
        on_gpu = false;
        valid_data = true;
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
        valid_data =true;
    }

    virtual void 
    send_dev()
    {
        assert(ctx != 0);
        ctx->queue.enqueueWriteBuffer(buffer, true, 0, byte_size(), data_ptr.get());
        on_gpu = true;
    }

    virtual void 
    recv_dev()
    {
        assert(ctx != 0);
        ctx->queue.enqueueReadBuffer(buffer, true, 0, byte_size(), data_ptr.get());
        on_gpu = false;
        valid_data = true;
    }

    size_t byte_size()
    {
        return size() * sizeof(NumT);
    }

    virtual void read_items(std::istream* in_file);
    virtual void write_items(std::ostream* out_file);

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

        write_items(out_file);
    }    

    cl_uint cols() const
    {
        return data_size;
    }


 protected:
    cl_uint data_size;

    bool on_gpu;
    bool valid_data;

    Bacon::Context* ctx;
    cl::Buffer buffer;
    boost::shared_array<NumT> data_ptr;

};

template<class NumT>
inline
void 
Array<NumT>::read_items(std::istream* in_file)
{
    for (unsigned int ii = 0; ii < size(); ++ii) {
        *in_file >> data_ptr[ii];
    }
    
    on_gpu = false;
    valid_data = true;
}

template<class NumT>
inline
void 
Array<NumT>::write_items(std::ostream* out_file)
{
    if (on_gpu)
        this->recv_dev();
    
    for (unsigned int ii = 0; ii < size(); ++ii) {
        *out_file << data_ptr[ii] << " ";
    }
    
    *out_file << std::endl;
}

template<>
inline
void 
Array<cl_uchar>::read_items(std::istream* in_file)
{
    for (unsigned int ii = 0; ii < size(); ++ii) {
        int tmp;
        *in_file >> tmp;
        data_ptr[ii] = (cl_uchar) tmp;
    }
    
    on_gpu = false;
    valid_data = true;
}

template<>
inline
void 
Array<cl_uchar>::write_items(std::ostream* out_file)
{
    if (on_gpu)
        this->recv_dev();

    for (unsigned int ii = 0; ii < size(); ++ii) {
        *out_file << (cl_uint) data_ptr[ii] << " ";
    }
    
    *out_file << std::endl;
}

template <class NumT>
bool 
operator==(Array<NumT>& aa, Array<NumT>& bb)
{
    if (aa.size() != bb.size())
        return false;
    
    for (unsigned int ii = 0; ii < aa.size(); ++ii) {
        if (aa.get(ii) != bb.get(ii))
                return false;
    }
    
    return true;
}

template <class NumT>
class Array2D : public Array<NumT> {
  public:
    Array2D()
        : Array<NumT>(), data_rows(0), data_cols(0)
    {
        // do nothing
    }

    Array2D(cl_uint yy, cl_uint xx) 
        : Array<NumT>(yy*xx), data_rows(yy), data_cols(xx)
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
        for (unsigned int ii = 0; ii < rows(); ++ii) {
            for (unsigned int jj = 0; jj < cols(); ++jj) {
                set(ii, jj, (NumT)(ii == jj ? 1 : 0));
            }
        }
    }

    void read(std::istream* in_file)
    {
        *in_file >> data_rows;
        *in_file >> data_cols;

        this->reallocate(data_rows * data_cols);
        this->read_items(in_file);
    }

    void write(std::ostream* out_file);

    cl_uint rows() const
    {
        return data_rows;
    }

    cl_uint cols() const
    {
        return data_cols;
    }

  protected:
    cl_uint data_rows;
    cl_uint data_cols;
};

template <class NumT>
inline
void
Array2D<NumT>::write(std::ostream* out_file)
{
    if (this->on_gpu)
        this->recv_dev();

    *out_file << rows() << " ";
    *out_file << cols() << "\n";
    
    for (unsigned int ii = 0; ii < rows(); ++ii) {
        for (unsigned int jj = 0; jj < cols(); ++jj) {
            *out_file << get(ii, jj) << " ";
        }
        * out_file << endl;
    }
}

template<>
inline
void
Array2D<cl_uchar>::write(std::ostream* out_file)
{
    if (this->on_gpu)
        this->recv_dev();

    *out_file << rows() << " ";
    *out_file << cols() << "\n";
    
    for (unsigned int ii = 0; ii < rows(); ++ii) {
        for (unsigned int jj = 0; jj < cols(); ++jj) {
            *out_file << (cl_uint) get(ii, jj) << " ";
        }
        *out_file << endl;
    }
}

template <class NumT>
bool 
operator==(Array2D<NumT>& aa, Array2D<NumT>& bb)
{
    if (aa.size() != bb.size() || aa.rows() != bb.rows() || aa.cols() != bb.cols())
        return false;

    for (unsigned int ii = 0; ii < aa.rows(); ++ii) {
        for (unsigned int jj = 0; jj < aa.cols(); ++jj) {
            if (aa.get(ii, jj) != bb.get(ii, jj))
                return false;
        }
    }
    
    return true;
}

template <class NumT>
bool
array_equals_debug(Array2D<NumT>& aa, Array2D<NumT>& bb)
{
    if (aa.size() != bb.size() || aa.rows() != bb.rows() || aa.cols() != bb.cols())
        return false;

    for (unsigned int ii = 0; ii < aa.rows(); ++ii) {
        for (unsigned int jj = 0; jj < aa.cols(); ++jj) {
            if (aa.get(ii, jj) != bb.get(ii, jj)) {
                cout << aa.get(ii, jj) << " != " << bb.get(ii, jj) << endl
                     << " at " << ii << " " << jj << endl;
                return false;
            }
        }
    }
    
    return true;
}


template <class NumT>
class Array3D : public Array<NumT> {
  public:
    Array3D()
        : Array<NumT>(), data_deep(0), data_rows(0), data_cols(0)
    {
        // do nothing
    }

    Array3D(cl_uint zz, cl_uint yy, cl_uint xx) 
        : Array<NumT>(zz*yy*xx), data_deep(zz), data_rows(yy), data_cols(xx)
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

        for (unsigned int kk = 0; kk < deep(); ++kk) {
            for (unsigned int ii = 0; ii < rows(); ++ii) {
                for (unsigned int jj = 0; jj < cols(); ++jj) {
                    *out_file << get(kk, ii, jj) << " ";
                }
                *out_file << "\n";
            }
            *out_file << endl;
        }
    }

  protected:
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

    for (unsigned int ii = 0; ii < aa.rows(); ++ii) {
        for (unsigned int jj = 0; jj < aa.cols(); ++jj) {
            for (unsigned int kk = 0; kk < aa.deep(); ++kk) {
                if (aa.get(ii, jj, kk) != bb.get(ii, jj, kk))
                    return false;
            }
        }
    }
    
    return true;
}

template <class NumT>
inline void
array_fill(Array<NumT> aa, NumT vv)
{
    aa.fill(vv);
}

} // namespace Bacon
#endif
