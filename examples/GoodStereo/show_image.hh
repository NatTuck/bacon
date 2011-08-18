#ifndef SHOW_IMAGE_HH
#define SHOW_IMAGE_HH

#include <opencv/cv.h>
#include <opencv/highgui.h>

#include "Bacon.hh"

void show_image(const char* title, cv::Mat image, int scale = 1);
void show_census(const char* title, uint64_t* data, int rows, int cols);
void show_census_a2d(const char* title, Bacon::Array2D<cl_ulong>& aa);
void show_pspace_slice(const char* title, Bacon::Array3D<cl_uchar>& pspace,
    int slice, int scale = 1);
void show_array2d(const char* title, Bacon::Array2D<cl_uchar>& aa, int scale = 1);
void show_image2d(const char* title, Bacon::Image2D<cl_uchar>& aa, int scale = 1);

#endif
