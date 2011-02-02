
#include "show_image.hh"

#define min(a, b) ((a)<(b)?(a):(b))

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
