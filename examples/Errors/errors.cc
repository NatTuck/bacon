
#include <fstream>
#include <iostream>
using std::cout;
using std::endl;

#include <string>
using std::string;

#include <stdlib.h>

#include "gen/Errors.hh"

int 
main(int argc, char* argv[])
{
    if (argc != 2) {
        cout << "Usage: ./errors input.dat" << endl;
        return 1;
    }

    Bacon::Array2D<int> aa;
    std::ifstream data(argv[1]);
    aa.read(&data);
       
    Errors errs;
    errs.test_errors(aa);

    return 0;
}
