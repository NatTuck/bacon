
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
random_test(int nn)
{
    MatMul mmul;

    Bacon::Array2D<float> aa(nn, nn);
    aa.fill_random();

    Bacon::Array2D<float> bb(nn, nn);
    bb.fill_identity_matrix();

    Bacon::Array2D<float> cc = mmul.mat_mul(aa, bb);
    
    if (aa == cc) {
        cout << "Random test succeeded." << endl;
    }
    else {
        cout << "Random test failed, arrays don't match." << endl;
    }
}

void
show_usage()
{
    cout << "Usage: ./mmul [-o output -a matrix1 -b matrix2 | -n size]" << endl;
    exit(1);
}

int 
main(int argc, char* argv[])
{
    int opt;
    
    string a_file("");
    string b_file("");
    string c_file("");

    int random_size = 0;

    while ((opt = getopt(argc, argv, "ha:b:o:n:")) != -1) {
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
        case 'n':
            random_size = atoi(optarg);
            break;
        case 'h':
            show_usage();
            return 0;
        default:
            show_usage();
            return 0;
        }
    }


    try {
        if (random_size != 0) {
            random_test(random_size);
        }
        else {
            run_test(c_file, a_file, b_file);
        }
    }
    catch(cl::Error ee) {
        cout << "Got error:\n";
        cout << " what: " << ee.what() << endl;
        cl_perror(ee.err());
    }
    return 0;
}