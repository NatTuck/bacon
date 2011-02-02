
#include <fstream>
#include <iostream>
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

cv::Mat
stereo_disparity(cv::Mat matL, cv::Mat matR)
{
    Stereo ss;

    Array2D<cl_uchar> aL = mat_to_array2d<cl_uchar>(matL);
    Array2D<cl_uchar> aR = mat_to_array2d<cl_uchar>(matR);

    Array2D<cl_ulong> cL = ss.sparse_census(aL);
    Array2D<cl_ulong> cR = ss.sparse_census(aR);

    cout << "one" << endl;

    cout << "two" << endl;

    cv::Mat xx = array2d_to_mat(cL);

    cout << "three" << endl;

    cout << "four" << endl;

    show_census("Census Left", cL.ptr(), cL.rows(), cL.cols());

    cout << "five" << endl;

    exit(0);

    //return array2d_to_mat(arD, CV_8UC1);
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

    cv::Mat disp  = stereo_disparity(left, right);
    
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
