#ifndef SHOW_IMAGE_HH
#define SHOW_IMAGE_HH

#include <opencv/cv.h>
#include <opencv/highgui.h>

#include "Bacon.hh"

void show_image(const char* title, cv::Mat image);
void show_census(const char* title, uint64_t* data, int rows, int cols);
void show_census_a2d(const char* title, Bacon::Array2D<cl_ulong>& aa);
void show_pspace_slice(const char* title, Bacon::Array3D<cl_uchar>& pspace, int slice);
void show_array2d(const char* title, Bacon::Array2D<cl_uchar>& aa);

#endif
