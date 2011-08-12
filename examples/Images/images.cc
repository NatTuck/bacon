
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

    while ((opt = getopt(argc, argv, "itx:y:")) != -1) {
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
    default:
        show_usage();
        return 0;
    }

    return 0;
}
