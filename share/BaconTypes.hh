#ifndef BACON_TYPES_HH
#define BACON_TYPES_HH
namespace Bacon {

#define __CL_ENABLE_EXCEPTIONS 1
#include <CL/cl.hpp>

template <class NumT>
class BaseBuffer {
  public:
    const cl_uint size;

  private:
    NumT* data_ptr;
};

template <class NumT>
class Array2D : public BaseBuffer {
  public:
    const cl_uint rows;
    const cl_uint cols;
};

template <class NumT>
class Array3D : public BaseBuffer {
  public:
    const cl_uint deep;
    const cl_uint rows;
    const cl_uint cols;
};

} // namespace Bacon
#endif
