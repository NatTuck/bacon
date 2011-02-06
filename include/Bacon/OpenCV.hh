#ifndef BACON_OPENCV_HH
#define BACON_OPENCV_HH

#include <cassert>
#include <stdint.h>

#include <opencv/cv.h>
#include <opencv/highgui.h>

#include <Bacon/Array.hh>

#include <iostream>
using std::cout;
using std::endl;

namespace Bacon {

template <class NumT>
Array2D<NumT>
mat_to_array2d(cv::Mat& aa)
{
    assert(aa.elemSize() == sizeof(NumT));

    Array2D<NumT> bb(aa.rows, aa.cols);

    for (int ii = 0; ii < aa.rows; ++ii) {
        for (int jj = 0; jj < aa.cols; ++jj) {
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

    for (int ii = 0; ii < aa.rows(); ++ii) {
        for (int jj = 0; jj < aa.cols(); ++jj) {
            bb.at<uint8_t>(ii, jj) = aa.get(ii, jj);
        }
    }

    return bb;
}

} // namespace Bacon

#endif
