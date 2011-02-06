
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

void
show_pspace_slice(Array3D<cl_uchar>& pspace, int slice)
{
    cv::Mat image(pspace.rows(), pspace.cols(), CV_8UC1);

    for (int ii = 0; ii < pspace.rows(); ++ii) {
        for (int jj = 0; jj < pspace.cols(); ++jj) {
            image.at<uint8_t>(ii, jj) = pspace.get(slice, ii, jj);
        }
    }

    show_image("GPU Pspace", image);
}


cv::Mat
stereo_disparity(cv::Mat matL, cv::Mat matR)
{
    Stereo ss;

    Array2D<cl_uchar> aL = mat_to_array2d<cl_uchar>(matL);
    Array2D<cl_uchar> aR = mat_to_array2d<cl_uchar>(matR);

    Array2D<cl_ulong> cL = ss.sparse_census(aL);
    Array2D<cl_ulong> cR = ss.sparse_census(aR);

#if 0
    show_census("Census Left", cL.ptr(), cL.rows(), cL.cols());
    show_census("Census Right", cR.ptr(), cR.rows(), cR.cols());
#endif

    cout << "one" << endl;

    Array3D<cl_uchar> pspace(1, cL.rows(), cL.cols());

    cout << "a3d size: " << pspace.deep() << " " << pspace.rows() 
         << " " << pspace.cols() << endl;

    ss.pspace_h(pspace, cL, cR, +1);

    cout << "three" << endl;

#if 1
    show_pspace_slice(pspace, 0);
    exit(0);
#endif

    cout << "four" << endl;

    Array2D<cl_uchar> arD = ss.disparity(pspace);

    cout << "seven" << endl;

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
