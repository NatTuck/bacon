#ifndef BACON_IMAGE_HH
#define BACON_IMAGE_HH

namespace Bacon {

template <class NumT>
class Image2D {
  public:
    Image2D()
        : data_size(0), on_gpu(false), valid_data(false)
    {

    }


 protected:
    cl_uint data_size;

    bool on_gpu;
    bool valid_data;

    Bacon::Context* ctx;
    cl::Image2D image;
    boost::shared_array<NumT> data_ptr;
};

} // namespace Bacon

#endif
