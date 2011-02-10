
#include <fstream>
#include <iostream>
#include <iomanip>
using std::cout;
using std::endl;

#include <string>
using std::string;

#include <stdlib.h>
#include <unistd.h>

#include <Bacon/OpenCV.hh>
#include "gen/Stereo.hh"

#include "show_image.hh"

using namespace Bacon;

void
show_pspace_slice(const char* title, Array3D<cl_uchar>& pspace, int slice)
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
show_array2d(const char* title, Array2D<cl_uchar>& aa)
{
    cv::Mat image(aa.rows(), aa.cols(), CV_8UC1);

    for (int ii = 0; ii < aa.rows(); ++ii) {
        for (int jj = 0; jj < aa.cols(); ++jj) {
            image.at<uint8_t>(ii, jj) = aa.get(ii, jj);
        }
    }

    show_image(title, image);    
}

cv::Mat
stereo_disparity(cv::Mat matL, cv::Mat matR)
{
    Stereo ss;
    ss.ctx.show_timing = true;

    Array2D<cl_uchar> aL = mat_to_array2d<cl_uchar>(matL);
    Array2D<cl_uchar> aR = mat_to_array2d<cl_uchar>(matR);

    Array2D<cl_ulong> cL = ss.sparse_census(aL);
    Array2D<cl_ulong> cR = ss.sparse_census(aR);

#if 0
    show_census("Census Left", cL.ptr(), cL.rows(), cL.cols());
    show_census("Census Right", cR.ptr(), cR.rows(), cR.cols());
#endif

    Array3D<cl_uchar> pspace(4, cL.rows(), cL.cols());

    ss.pspace_h(pspace, cL, cR, +1);
    ss.pspace_v(pspace, cL, cR, +1);

    Array2D<cl_uchar> dsL = ss.half_disparity(cL, cR, pspace, +1);
    //Array2D<cl_uchar> dsL = ss.median_filter(arL);

    ss.pspace_h(pspace, cR, cL, -1);
    ss.pspace_v(pspace, cR, cL, -1);

    Array2D<cl_uchar> dsR = ss.half_disparity(cR, cL, pspace, -1);
    //Array2D<cl_uchar> dsR = ss.median_filter(arR);

    show_array2d("Left", dsL);
    show_array2d("Right", dsR);
    
    Array2D<cl_uchar> arD = ss.consistent_pixels(dsL, dsR);

    return array2d_to_mat(arD);
}

void
show_usage()
{
    cout << "Usage: ./stereo [-c ground.png] [-o disp.png] left.png right.png" << endl;
    exit(1);
}

int 
main(int argc, char* argv[])
{
    int opt;

    string out_file("");
    string ground_truth("");

    while ((opt = getopt(argc, argv, "ho:")) != -1) {
        switch(opt) {
        case 'o':
            out_file = string(optarg);
            break;
        case 'c':
            ground_truth = string(optarg);
            break;
        case 'h':
        default:
            show_usage();
            return 0;
        }
    }

    if (argc != 3) {
        show_usage();
        return 0;
    }

    cv::Mat left  = cv::imread(argv[1], CV_LOAD_IMAGE_GRAYSCALE);
    cv::Mat right = cv::imread(argv[2], CV_LOAD_IMAGE_GRAYSCALE);

    cout.precision(2);
    cout << std::fixed;

    Bacon::Timer timer;
    cv::Mat disp  = stereo_disparity(left, right);
    double total_time = timer.time();
    cout << "One frame disparity took: " << total_time << endl;
    
    if (ground_truth != "") {
        cv::Mat ground = cv::imread(ground_truth, CV_LOAD_IMAGE_GRAYSCALE);
        //show_difference(ground, disp);
    }

    cv::namedWindow("Disparity Map", CV_WINDOW_AUTOSIZE);
    cv::imshow("Disparity Map", disp);
    cv::waitKey(0);

    if (out_file != "")
        imwrite(out_file, disp);

    return 0;
}
