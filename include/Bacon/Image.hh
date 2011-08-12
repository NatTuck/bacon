#ifndef BACON_IMAGE_HH
#define BACON_IMAGE_HH

#include <iostream>
using std::cout;
using std::endl;

#include "Bacon/Array.hh"

namespace Bacon {

template <class NumT>
class Image2D : public Array2D<NumT> {
  public:
    Image2D()
        : Array2D<NumT>()
    {
        // do nothing
    }

    Image2D(int yy, int xx)
    {
        this->data_cols = yy;
        this->data_rows = xx;
        reallocate(yy * xx);
    }

    virtual void 
    reallocate(int size)
    {
        assert(this->ctx != 0);
        this->data_size = size;
        this->data_ptr = boost::shared_array<NumT>(new NumT[this->data_size]);
        this->on_gpu = false;
        this->valid_data = false;
        image = cl::Image2D(this->ctx->ctx, 0, image_format(),
            this->data_cols, this->data_rows, 0, 0);
    }

    cl::Image2D data()
    {
        if (!this->on_gpu)
            send_dev();
        return image;
    }

    cl::ImageFormat image_format();

    void send_dev()
    {
        assert(this->ctx != 0);
        this->on_gpu = true;

        cl::size_t<3> origin;
        origin[0] = 0;
        origin[1] = 0;
        origin[2] = 0;
        cl::size_t<3> region;
        region[0] = this->data_cols;
        region[1] = this->data_rows;
        region[2] = 1;
        
        this->ctx->queue.enqueueWriteImage(image, true, origin, region, 
            0, 0, this->data_ptr.get());
    }

    void recv_dev()
    {
        assert(this->ctx != 0);
        this->on_gpu = false;

        cl::size_t<3> origin;
        origin[0] = 0;
        origin[1] = 0;
        origin[2] = 0;
        cl::size_t<3> region;
        region[0] = this->data_cols;
        region[1] = this->data_rows;
        region[2] = 1;

        this->ctx->queue.enqueueReadImage(image, true, origin, region, 
            0, 0, this->data_ptr.get());
    }

 protected:
    cl::Image2D image;
};

template<> 
inline
cl::ImageFormat
Image2D<cl_uchar>::image_format()
{
    return cl::ImageFormat(CL_R, CL_UNSIGNED_INT8);
}

template<>
inline
cl::ImageFormat
Image2D<cl_ulong>::image_format()
{
    return cl::ImageFormat(CL_RGBA, CL_UNSIGNED_INT16);
}

} // namespace Bacon

#endif
