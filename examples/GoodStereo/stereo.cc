
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

cv::Mat
stereo_disparity(cv::Mat matL, cv::Mat matR)
{
    Stereo ss;

    Bacon::Timer tt_full;

    // convert inputs to Array2D
    // scale
    // census 1/2
    // SGM 1/2
    // consistency 1/2
    // fill unknown pixels magically
    // census full
    // restricted range matching
    // consistency check

    Bacon::Timer tt_conv;
    Array2D<cl_uchar> aL = mat_to_array2d<cl_uchar>(matL, 8);
    Array2D<cl_uchar> aR = mat_to_array2d<cl_uchar>(matR, 8);
    cout << "Conversion: " << tt_conv.time() << endl;

    Bacon::Timer tt_scale;
    Array2D<cl_uchar> hL = ss.scale_half(aL);
    Array2D<cl_uchar> hR = ss.scale_half(aR);
    cout << "Scale: " << tt_conv.time() << endl;    

    Bacon::Timer tt_ch;
    Array2D<cl_ulong> chL = ss.sparse_census(hL);
    Array2D<cl_ulong> chR = ss.sparse_census(hR);
    cout << "Census Half: " << tt_ch.time() << endl;

    Array3D<cl_uchar> pL(8, chL.rows(), chL.cols());
    ss.sgm_h(pL, chL, chR, +1);

    show_pspace_slice("pL[0]", pL, 0);

    //ss.sgm_v(pL, chL, chR, +1);


    Array3D<cl_ulong> pR(8, chR.rows(), chR.cols());

    

    cv::Mat dispM = array2d_to_mat(hL);

    cout << "One frame disparity took: " << tt_full.time() << endl;
    return dispM;
}

float
avg_diff(cv::Mat& imA, cv::Mat& imB)
{
    const int FUDGE = 7;
    cv::Size  sz = imB.size();

    int count = 0;

    for (int ii = 0; ii < sz.height; ++ii) {
        for (int jj = 0; jj < sz.width; ++jj) {
            unsigned char vA = imA.at<unsigned char>(ii, jj);
            unsigned char vB = imB.at<unsigned char>(ii, jj);

            // Skip unknown values.
            if (vA == 0 && vB != 0)
                continue;

            if (abs(vA - vB) > FUDGE)
                ++count;
        }
    }

    return ((float) count) / ((float) sz.width * sz.height);
}

float
count_unknown(cv::Mat& imA, cv::Mat& imB)
{
    cv::Size  sz = imB.size();

    int count = 0;

    for (int ii = 0; ii < sz.height; ++ii) {
        for (int jj = 0; jj < sz.width; ++jj) {
            unsigned char vA = imA.at<unsigned char>(ii, jj);
            unsigned char vB = imB.at<unsigned char>(ii, jj);

            // Count unknown values.
            if (vA == 0 && vB != 0) 
                ++count;
        }
    }

    return ((float) count) / ((float) sz.width * sz.height);
}

void
show_usage()
{
    cout << "Usage: ./stereo [-n] [-c ground.png] [-o disp.png] left.png right.png" << endl;
    exit(1);
}

int 
main(int argc, char* argv[])
{
    int opt;

    string out_file("");
    string ground_truth("");

    while ((opt = getopt(argc, argv, "hno:c:")) != -1) {
        switch(opt) {
        case 'o':
            out_file = string(optarg);
            break;
        case 'c':
            ground_truth = string(optarg);
            break;
        case 'n':
            Bacon::use_opencl_cpu = true;
            break;
        case 'h':
        default:
            show_usage();
            return 0;
        }
    }

    if (argc - optind != 2) {
        show_usage();
        return 0;
    }

    cv::Mat left  = cv::imread(argv[optind+0], CV_LOAD_IMAGE_GRAYSCALE);
    cv::Mat right = cv::imread(argv[optind+1], CV_LOAD_IMAGE_GRAYSCALE);

    cout.precision(4);
    cout << std::fixed;

    cv::Mat disp;

    cout << "First" << endl;
    disp = stereo_disparity(left, right);

    cout << "Again" << endl;
    disp = stereo_disparity(left, right);

    // Scale to match ground truth.
    disp *= 2;
    
    if (!ground_truth.empty()) {
        cv::Mat imG = cv::imread(ground_truth, CV_LOAD_IMAGE_GRAYSCALE);
        float wrong = avg_diff(disp, imG);
        printf("%.03f of pixels different from ground truth.\n", wrong);

        float missing = count_unknown(disp, imG);
        printf("%.03f of pixels are unknown over ground truth.\n", missing);
    }

    cv::namedWindow("Disparity Map", CV_WINDOW_AUTOSIZE);
    cv::imshow("Disparity Map", disp);
    cv::waitKey(0);

    if (out_file != "")
        imwrite(out_file, disp);

    return 0;
}
