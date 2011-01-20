
#include <fstream>
#include <iostream>
using std::cout;
using std::endl;

#include <string>
using std::string;

#include <stdlib.h>
#include <unistd.h>

#include "gen/Bacon.hh"
#include "gen/MatMul.hh"
#include "gen/cl_perror.hh"

void
run_test(string c_file, string a_file, string b_file)
{
    MatMul mmul;

    Bacon::Array2D<float> aa;
    Bacon::Array2D<float> bb;

    std::ifstream aaf(a_file.c_str());
    aa.read(&aaf);
    
    std::ifstream bbf(b_file.c_str());
    bb.read(&bbf);

    Bacon::Array2D<float> cc = mmul.mat_mul(aa, bb);

    if (c_file == "") {
        cc.write(&cout);
    }
    else {
        std::ofstream outf(c_file.c_str());
        cc.write(&outf);
    }
}

void
show_usage()
{
    cout << "Usage: ./summa -o output -a matrix1 -b matrix2" << endl;
    exit(1);
}

int 
main(int argc, char* argv[])
{
    int opt;
    
    string a_file("");
    string b_file("");
    string c_file("");

    while ((opt = getopt(argc, argv, "ha:b:o:")) != -1) {
        switch(opt) {
        case 'a':
            a_file = string(optarg);
            break;
        case 'b':
            b_file = string(optarg);
            break;
        case 'o':
            c_file = string(optarg);
            break;
        case 'h':
            show_usage();
            return 0;
        default:
            show_usage();
            return 0;
        }
    }

    if (a_file == "" || b_file == "") {
        show_usage();
        return 1;
    }

    try {
        run_test(c_file, a_file, b_file);
    }
    catch(cl::Error ee) {
        cout << "Got error:\n";
        cout << " what: " << ee.what() << endl;
        cl_perror(ee.err());
    }
    return 0;
}
