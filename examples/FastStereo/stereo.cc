
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
    //ss.ctx.show_timing = true;

    Bacon::Timer stereo_timer;

    Bacon::Timer tt0;
    Array2D<cl_uchar> aL = mat_to_array2d<cl_uchar>(matL, 8);
    Array2D<cl_uchar> aR = mat_to_array2d<cl_uchar>(matR, 8);

    Array2D<cl_ulong> cL = ss.sparse_census(aL);
    Array2D<cl_ulong> cR = ss.sparse_census(aR);
    double to_census = tt0.time();
    cout << "Convert and census took: " << to_census << endl;

#if 0
    show_census("Census Left", cL.ptr(), cL.rows(), cL.cols());
    show_census("Census Right", cR.ptr(), cR.rows(), cR.cols());
    exit(0);
#endif

    Array3D<cl_uchar> pspace(4, cL.rows(), cL.cols());

    //    ss.pspace_h(pspace, cL, cR, +1);

#if 0
    show_pspace_slice("pspace 0", pspace, 0);
    show_pspace_slice("pspace 1", pspace, 1);
    exit(0);
#endif

    //ss.pspace_v(pspace, cL, cR, +1);

#if 0
    show_pspace_slice("pspace 2", pspace, 2);
    show_pspace_slice("pspace 3", pspace, 3);
#endif

    Array2D<cl_uchar> arL = ss.half_disparity(cL, cR, pspace, +1);
    Array2D<cl_uchar> dsL = ss.median_filter(arL);

    //ss.pspace_h(pspace, cR, cL, -1);
    //ss.pspace_v(pspace, cR, cL, -1);

    Array2D<cl_uchar> arR = ss.half_disparity(cR, cL, pspace, -1);
    Array2D<cl_uchar> dsR = ss.median_filter(arR);

#if 0
    show_array2d("Left", dsL);
    show_array2d("Right", dsR);
#endif    

    Array2D<cl_uchar> arD = ss.consistent_pixels(dsL, dsR);

    cv::Mat dispM = array2d_to_mat(arD);

    double total_time = stereo_timer.time();
    cout << "One frame disparity took: " << total_time << endl;

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

    cv::Mat disp  = stereo_disparity(left, right);

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
