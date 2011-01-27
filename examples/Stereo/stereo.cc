
#include <fstream>
#include <iostream>
using std::cout;
using std::endl;

#include <string>
using std::string;

#include <stdlib.h>
#include <unistd.h>

#include "gen/Stereo.hh"

cv::Mat
stereo_disparity(cv::Mat matL, cv::Mat matR)
{
    Bacon::Array2D<cl_uchar> arL = mat2array(matL);
    Bacon::Array2D<cl_uchar> arR = mat2array(matR);

    
    Bacon::Array2D<cl_uchar> arD = calc

    cv::Mat matD = 
}

void
show_usage()
{
    cout << "Usage: ./stereo -o disp.png" << endl;
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

    cv::Mat left  = imread(argv[1]);
    cv::Mat right = imread(argv[2]);

    cv::Mat disp  = stereo_disparity(left, right);
    
    if (ground_truth != "") {
        cv::Mat ground = imread(ground_truth);
        show_difference(ground, disp);
    }

    cv::namedWindow("Disparity Map", CV_WINDOW_AUTOSIZE);
    cv::imshow("Disparity Map", disp);
    cv::waitKey(0);

    if (out_file != "")
        imwrite(out_file, disp);

    return 0;
}
