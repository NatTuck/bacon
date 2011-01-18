
#include <fstream>
#include <iostream>
using std::cout;
using std::endl;

#include <string>
using std::string;

#include <stdlib.h>

#include "gen/Bacon.hh"
#include "gen/Errors.hh"
#include "gen/cl_perror.hh"

int 
main(int argc, char* argv[])
{
    if (argc != 2) {
        cout << "Usage: ./errors input.dat" << endl;
        return 1;
    }

    try {
        Bacon::Array2D<int> aa;
        std::ifstream data(argv[1]);
        aa.read(&data);
       
        Errors errs;
        errs.test_errors(aa);
    }
    catch(cl::Error ee) {
        cout << "Got error:\n";
        cout << " what: " << ee.what() << endl;
        cl_perror(ee.err());
    }

    return 0;
}
