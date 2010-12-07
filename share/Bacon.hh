#ifndef BACON_COMMON_HH
#define BACON_COMMON_HH
namespace Bacon {

#include <CL/cl.hpp>

using std::size_t;

template <class NumT>
class Array2D {
  public:
    const size_t rows;
    const size_t cols;

  private:
    NumT* data_ptr;
};

template <class NumT>
class Array3D {
  public:
    const size_t rows;
    const size_t cols;
    const size_t deep;

  private:
    NumT* data_ptr;
};

} // namespace Bacon
#endif
