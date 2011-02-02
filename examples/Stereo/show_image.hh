#ifndef SHOW_IMAGE_HH
#define SHOW_IMAGE_HH

#include <opencv/cv.h>
#include <opencv/highgui.h>

#include <Bacon/Array.hh>

void show_image(const char* title, cv::Mat image);
void show_census(const char* title, uint64_t* data, int rows, int cols);

#endif
