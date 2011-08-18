
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
stereo_disparity(Stereo& ss, cv::Mat matL, cv::Mat matR)
{
    Bacon::Kernel::show_timing = true;
    const int SGM_N   = 8;
    const int SHOW_SC = 4;

    Bacon::Timer tt_full;

    // convert inputs to Array2D
    Bacon::Timer tt_conv;
    Image2D<cl_uchar> aL = mat_to_image2d<cl_uchar>(matL, 8);
    Image2D<cl_uchar> aR = mat_to_image2d<cl_uchar>(matR, 8);
    cout << "Conversion: " << tt_conv.time() << endl;

    // scale
    Bacon::Timer tt_scale;
    Image2D<cl_uchar> hL = ss.scale_half(aL);
    Image2D<cl_uchar> hR = ss.scale_half(aR);
    cout << "Scale: " << tt_conv.time() << endl;

    // census 1/2
    Bacon::Timer tt_ch;
    Image2D<cl_ulong> chL = ss.sparse_census(hL);
    Image2D<cl_ulong> chR = ss.sparse_census(hR);
    cout << "Census Half: " << tt_ch.time() << endl;

    // SGM 1/2 L
    Array3D<cl_uchar> pL(8, chL.rows(), chL.cols());

    Bacon::Timer tt_sgm_hL;
    ss.sgm_h(pL, chL, chR, +1, SGM_N);
    cout << "SGM HL: " << tt_sgm_hL.time() << endl;
    //show_pspace_slice("pL[0]", pL, 0, SHOW_SC);
    //show_pspace_slice("pL[1]", pL, 1, SHOW_SC);

    Bacon::Timer tt_sgm_vL; 
    ss.sgm_v(pL, chL, chR, +1, SGM_N);
    cout << "SGM VL: " << tt_sgm_vL.time() << endl;
    //show_pspace_slice("pL[2]", pL, 2, SHOW_SC);
    //show_pspace_slice("pL[3]", pL, 3, SHOW_SC);
    
    //show_pspace_slice("pl[6]", pL, 6, SHOW_SC);
    //show_pspace_slice("pl[7]", pL, 7, SHOW_SC);

    // merge 1/2 L
    Bacon::Timer tt_dhL; 
    Image2D<cl_uchar> dhL = ss.merge_pspace(pL, SGM_N);
    cout << "Merge L: " << tt_dhL.time() << endl;

    //show_image2d("merge L", dhL, SHOW_SC);
    
    // SGM 1/2 R
    Array3D<cl_uchar> pR(8, chR.rows(), chR.cols());

    Bacon::Timer tt_sgm_hR;
    ss.sgm_h(pR, chR, chL, -1, SGM_N);
    cout << "SGM HR: " << tt_sgm_hR.time() << endl;
    //show_pspace_slice("pR[0]", pR, 0, SHOW_SC);
    //show_pspace_slice("pR[1]", pR, 1, SHOW_SC);

    Bacon::Timer tt_sgm_vR; 
    ss.sgm_v(pR, chR, chL, -1, SGM_N);
    cout << "SGM VR: " << tt_sgm_vR.time() << endl;
    //show_pspace_slice("pR[2]", pR, 2);
    //show_pspace_slice("pR[3]", pR, 3);

    // merge 1/2 R
    Bacon::Timer tt_dhR;
    Image2D<cl_uchar> dhR = ss.merge_pspace(pR, SGM_N);
    cout << "Merge R: " << tt_dhR.time() << endl;
    //show_image2d("merge R", dhR, SHOW_SC);

    dhL = ss.median_filter(dhL);
    dhR = ss.median_filter(dhR);

    // consistency 1/2
    Image2D<cl_uchar> dhL1 = ss.consistent_pixels(dhL, dhR, +1);
    Image2D<cl_uchar> dhR1 = ss.consistent_pixels(dhR, dhL, -1);
    
    // census full
    Image2D<cl_ulong> cL = ss.sparse_census(aL);
    Image2D<cl_ulong> cR = ss.sparse_census(aR);

    // restricted range matching
    Image2D<cl_uchar> dL = ss.narrow_disparity(cL, cR, +1, dhL1);
    dL = ss.median_filter(dL);

    Image2D<cl_uchar> dR = ss.narrow_disparity(cR, cL, -1, dhR1);
    dR = ss.median_filter(dR);

    // consistency check
    Image2D<cl_uchar> dF = ss.consistent_pixels(dL, dR, +1);

    cv::Mat dispM = array2d_to_mat(dF);
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

    Stereo ss;
    cv::Mat disp;

    cout << "First" << endl;
    disp = stereo_disparity(ss, left, right);

    //cout << "Again" << endl;
    disp = stereo_disparity(ss, left, right);

    // Scale to match ground truth.
    disp *= 2;
    
    if (!ground_truth.empty()) {
        cv::Mat imG = cv::imread(ground_truth, CV_LOAD_IMAGE_GRAYSCALE);
        float wrong = avg_diff(disp, imG);
        printf("%.03f of pixels different from ground truth.\n", wrong);

        float missing = count_unknown(disp, imG);
        printf("%.03f of pixels are unknown over ground truth.\n", missing);
    }

#if 1
    cv::namedWindow("Disparity Map", CV_WINDOW_AUTOSIZE);
    cv::imshow("Disparity Map", disp);
    cv::waitKey(0);
#endif

    if (out_file != "")
        imwrite(out_file, disp);

    return 0;
}
