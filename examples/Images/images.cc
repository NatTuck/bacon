
#include <fstream>
#include <iostream>
using std::cout;
using std::cin;
using std::endl;

#include <string>
using std::string;

#include <stdlib.h>
#include <unistd.h>

#include "gen/Images.hh"

void
test_show_indexes(int yy, int xx)
{
    Images bcn;

    Bacon::Image2D<cl_uchar> image = bcn.show_indexes(yy, xx);
    image.write(&cout);
}

void
test_copy_to_array()
{
    Images bcn;
    
    Bacon::Image2D<cl_uchar> image;
    image.read(&cin);

    Bacon::Array2D<cl_uchar> arry = bcn.copy_to_array(image);
    arry.write(&cout);
}

void
test_add_ten_long()
{
    Images bcn;

    Bacon::Image2D<cl_ulong> aa;
    aa.read(&cin);

    Bacon::Image2D<cl_ulong> bb = bcn.add_ten_long(aa);
    bb.write(&cout);
}

void
test_image3d(int nn)
{
    Images bcn;

    Bacon::Image2D<cl_uchar> tmp1(nn, nn);
    tmp1.send_dev();

    Bacon::Image3D<cl_uchar> tmp(nn, nn, nn);
    tmp.send_dev();

    Bacon::Image3D<cl_uchar> a3d = bcn.write_image3D(nn);

    Bacon::Array<cl_int>   csums = bcn.sum_image3D_cols(a3d, nn);
    csums.write(&cout);
}

void
show_usage()
{
    cout << "Usage: ./arrays [ -i -y N -x N | -t ]" << endl;
    exit(1);
}

int 
main(int argc, char* argv[])
{
    int opt;

    int xx = 0;
    int yy = 0;

    int mode = 0;

    const int INDEX_MODE = 1;
    const int COPYA_MODE = 2;
    const int ADD10_MODE = 3;
    const int IMG3D_MODE = 4;

    while ((opt = getopt(argc, argv, "ita3x:y:")) != -1) {
        switch(opt) {
        case 'x':
            xx = atoi(optarg);
            break;
        case 'y':
            yy = atoi(optarg);
            break;
        case 'i':
            mode = INDEX_MODE;
            break;
        case 't':
            mode = COPYA_MODE;
            break;
        case 'a':
            mode = ADD10_MODE;
            break;
        case '3':
            mode = IMG3D_MODE;
            break;
        case 'h':
            show_usage();
            return 0;
        default:
            show_usage();
            return 0;
        }
    }

    switch (mode) {
    case INDEX_MODE:
        if (xx == 0 || yy == 0) {
            show_usage();
            return 0;
        }

        test_show_indexes(yy, xx);
        break;
    case COPYA_MODE:
        test_copy_to_array();
        break;
    case ADD10_MODE:
        test_add_ten_long();
        break;
    case IMG3D_MODE:
        test_image3d(8);
        break;
    default:
        show_usage();
        return 0;
    }

    return 0;
}
