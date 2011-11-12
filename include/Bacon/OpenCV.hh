#ifndef BACON_OPENCV_HH
#define BACON_OPENCV_HH

#include <cassert>
#include <stdint.h>
#include <stddef.h>

#include <opencv/cv.h>
#include <opencv/highgui.h>

#include <Bacon/Array.hh>
#include <Bacon/Image.hh>

#include <iostream>
using std::cout;
using std::endl;

namespace Bacon {

inline cl_uint round_to_next(cl_uint aa, cl_uint) { return aa; }

template <class NumT>
Array2D<NumT>
mat_to_array2d(cv::Mat& aa, int rtn = 1)
{
    assert(aa.elemSize() == sizeof(NumT));

    cl_uint rows = round_to_next(aa.rows, rtn);
    cl_uint cols = round_to_next(aa.cols, rtn);

    Array2D<NumT> bb(rows, cols);

    for (uint32_t ii = 0; ii < (uint32_t) aa.rows; ++ii) {
        for (uint32_t jj = 0; jj < (uint32_t) aa.cols; ++jj) {
            bb.set(ii, jj, aa.at<NumT>(ii, jj));
        }
    }

    return bb;
}

template <class NumT>
cv::Mat
array2d_to_mat(Array2D<NumT>& aa)
{
    cv::Mat bb(aa.rows(), aa.cols(), CV_8UC1);

    for (unsigned int ii = 0; ii < aa.rows(); ++ii) {
        for (unsigned int jj = 0; jj < aa.cols(); ++jj) {
            bb.at<uint8_t>(ii, jj) = aa.get(ii, jj);
        }
    }

    return bb;
}

template <class NumT>
Image2D<NumT>
mat_to_image2d(const cv::Mat& aa, int rtn = 1)
{
    assert(aa.elemSize() == sizeof(NumT));

    cl_uint rows = round_to_next(aa.rows, rtn);
    cl_uint cols = round_to_next(aa.cols, rtn);

    Image2D<NumT> bb(rows, cols);

    for (uint32_t ii = 0; ii < (uint32_t) aa.rows; ++ii) {
        for (uint32_t jj = 0; jj < (uint32_t) aa.cols; ++jj) {
            bb.set(ii, jj, aa.at<NumT>(ii, jj));
        }
    }

    return bb;
}

template <class NumT>
cv::Mat
image2d_to_mat(Image2D<NumT>& aa);

template<>
cv::Mat
image2d_to_mat(Image2D<cl_uchar>& aa)
{
    cv::Mat bb(aa.rows(), aa.cols(), CV_8UC1);

    for (unsigned int ii = 0; ii < aa.rows(); ++ii) {
        for (unsigned int jj = 0; jj < aa.cols(); ++jj) {
            bb.at<uint8_t>(ii, jj) = aa.get(ii, jj);
        }
    }

    return bb;
}

template<>
cv::Mat
image2d_to_mat(Image2D<cl_short>& aa)
{
    cv::Mat bb(aa.rows(), aa.cols(), CV_16SC1);

    for (unsigned int ii = 0; ii < aa.rows(); ++ii) {
        for (unsigned int jj = 0; jj < aa.cols(); ++jj) {
            bb.at<int16_t>(ii, jj) = aa.get(ii, jj);
        }
    }

    return bb;
}

} // namespace Bacon

#endif
