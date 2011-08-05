
#include "show_image.hh"

inline int
min(int aa, int bb)
{
    return (aa < bb) ? aa : bb;
}

void
show_image(const char* title, cv::Mat image)
{
    cv::namedWindow(title, CV_WINDOW_AUTOSIZE);
    cv::imshow(title, image);
    cv::waitKey(0);
}

void
show_census(const char* title, uint64_t* data, int rows, int cols)
{
    cv::Mat image(rows, cols, CV_8UC1);
    
    for (int ii = 0; ii < rows; ++ii) {
        for (int jj = 0; jj < cols; ++jj) {
            uint64_t cv = data[ii*cols + jj];
            image.at<unsigned char>(ii, jj) = min(255, 4 * cv);
        }
    }

    show_image(title, image);
}

void
show_pspace_slice(const char* title, Bacon::Array3D<cl_uchar>& pspace, int slice)
{
    cv::Mat image(pspace.rows(), pspace.cols(), CV_8UC1);

    for (int ii = 0; ii < pspace.rows(); ++ii) {
        for (int jj = 0; jj < pspace.cols(); ++jj) {
            image.at<uint8_t>(ii, jj) = pspace.get(slice, ii, jj);
        }
    }

    show_image(title, image);
}

void
show_array2d(const char* title, Bacon::Array2D<cl_uchar>& aa)
{
    cv::Mat image(aa.rows(), aa.cols(), CV_8UC1);

    for (int ii = 0; ii < aa.rows(); ++ii) {
        for (int jj = 0; jj < aa.cols(); ++jj) {
            image.at<uint8_t>(ii, jj) = aa.get(ii, jj);
        }
    }

    show_image(title, image);    
}
