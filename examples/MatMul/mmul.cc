
#include <fstream>
#include <iostream>
using std::cout;
using std::endl;

#include <string>
using std::string;

#include <stdlib.h>
#include <unistd.h>

#include <Bacon/Timer.hh>

#include "gen/MatMul.hh"

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
random_test(int nn, bool check = true, bool timing = false)
{
    MatMul mmul;

    Bacon::Timer tt;
    double seconds;

    Bacon::Array2D<float> aa(nn, nn);
    aa.fill_random();

    Bacon::Array2D<float> bb(nn, nn);
    bb.fill_identity_matrix();

    tt.reset();
    Bacon::Array2D<float> cc = mmul.mat_mul(aa, bb);
    seconds = tt.time();

    if (timing) {
        cout << "First run took " << seconds << " seconds." << endl;

        tt.reset();
        cc = mmul.mat_mul(aa, bb);
        seconds = tt.time();

        cout << "Second run took " << seconds << " seconds." << endl;
    }


    if(!check) {
        cout << "Result not checked." << endl;
        return;
    }
 
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
    bool check_result = false;
    bool print_timing = false;

    while ((opt = getopt(argc, argv, "hpta:b:o:n:c")) != -1) {
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
        case 'c':
            check_result = true;
            break;
        case 'p':
            Bacon::use_opencl_cpu = true;
            break;
        case 't':
            print_timing = true;
            break;
        case 'h':
            show_usage();
            return 0;
        default:
            show_usage();
            return 0;
        }
    }


    if (random_size != 0) {
        random_test(random_size, check_result, print_timing);
    }
    else {
        run_test(c_file, a_file, b_file);
    }

    return 0;
}
