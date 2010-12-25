#ifndef BACON_TYPES_HH
#define BACON_TYPES_HH

#define __CL_ENABLE_EXCEPTIONS 1
#include <CL/cl.hpp>

namespace Bacon {

template <class NumT>
class BaseBuffer {
  public:
    BaseBuffer(cl_uint xx) 
        : size(xx)
    {
        data = new NumT[size];
    }

    ~BaseBuffer()
    {
        delete[] data;
    }

    void fill(NumT vv)
    {
        for(int ii = 0; ii < size; ++ii)
            data[ii] = vv;
    }

    const cl_uint size;

    NumT* data;
};

template <class NumT>
class Array2D : public BaseBuffer<NumT> {
  public:
    Array2D(cl_uint yy, cl_uint xx) 
        : rows(yy), cols(xx), BaseBuffer<NumT>(yy*xx)
    {
        // do nothing
    }

    NumT
    get(cl_uint yy, cl_uint xx)
    {
        return this->data[yy*cols + xx];
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
