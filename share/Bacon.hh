#ifndef BACON_COMMON_HH
#define BACON_COMMON_HH
namespace Bacon {

#include <CL/cl.hpp>

class BaseContext {
  public:
    BaseContext();
    ~BaseContext();
};

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
