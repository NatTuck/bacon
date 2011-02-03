
#include <fstream>
#include <iostream>
using std::cout;
using std::endl;

#include <string>
using std::string;

#include <stdlib.h>
#include <unistd.h>

#include "gen/Arrays.hh"

void
test_vflood(int xx, int yy)
{
    Arrays bcn;

    Bacon::Array<int> aa(xx);

    for (int ii = 0; ii < xx; ++ii) {
        aa.set(ii, ii * 10);
    }

    Bacon::Array2D<int> bb = bcn.vflood(aa, yy);

    bb.write(&cout);
}

void
show_usage()
{
    cout << "Usage: ./arrays [-f N]" << endl;
    exit(1);
}

int 
main(int argc, char* argv[])
{
    int opt;

    int xx = 0;
    int yy = 0;

    int mode = 0;

    const int FLOOD_MODE = 1;

    while ((opt = getopt(argc, argv, "hfx:y:")) != -1) {
        switch(opt) {
        case 'x':
            xx = atoi(optarg);
            break;
        case 'y':
            yy = atoi(optarg);
            break;
        case 'f':
            mode = FLOOD_MODE;
            break;
        case 'h':
            show_usage();
            return 0;
        default:
            show_usage();
            return 0;
        }
    }

    if (mode == 0 || xx == 0 || yy == 0) {
        show_usage();
        return 0;
    }

    switch (mode) {
    case 1:
        test_vflood(xx, yy);
        break;
    default:
        show_usage();
        return 0;
    }

    return 0;
}
