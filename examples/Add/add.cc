
#include <fstream>
#include <iostream>
using std::cout;
using std::endl;

#include <string>
using std::string;

#include <stdlib.h>
#include <unistd.h>

#include "gen/Add.hh"

void
run_test(string c_file, string a_file, string b_file, int nn)
{
    Add adder;

    Bacon::Array2D<cl_int> aa(nn, nn);
    Bacon::Array2D<cl_int> bb(nn, nn);

    if (a_file == "") {
        aa.fill(1);
    }
    else {
        std::ifstream aaf(a_file.c_str());
        aa.read(&aaf);
    }
    
    if (b_file == "") {
        bb.fill(2);
    }
    else {
        std::ifstream bbf(b_file.c_str());
        bb.read(&bbf);
    }

    assert(aa.size() == bb.size());

    Bacon::Array2D<cl_int> cc = adder.add(aa, bb);

    if (c_file == "") {
        cc.write(&cout);
    }
    else {
        std::ofstream outf(c_file.c_str());
        cc.write(&outf);
    }
}

void
run_doubles_test(string c_file, int nn)
{
    Add adder;

    Bacon::Array2D<double> aa(nn, nn);
    Bacon::Array2D<double> bb(nn, nn);

    aa.fill(1.5);
    bb.fill(2.0);

    Bacon::Array2D<double> cc = adder.add_doubles(aa, bb);

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
    cout << "Usage: ./add -o output -a matrix1 -b matrix2" << endl;
    exit(1);
}

int 
main(int argc, char* argv[])
{
    int opt;
    
    string a_file("");
    string b_file("");
    string c_file("");

    int gen_size = 2;

    bool use_doubles = false;

    while ((opt = getopt(argc, argv, "hcda:b:o:n:")) != -1) {
        switch(opt) {
        case 'a':
            a_file = string(optarg);
            break;
        case 'b':
            b_file = string(optarg);
            break;
        case 'n':
            gen_size = atoi(optarg);
            break;
        case 'o':
            c_file = string(optarg);
            break;
        case 'c':
            Bacon::use_opencl_cpu = true;
            break;
        case 'd':
            use_doubles = true;
            break;
        case 'h':
        default:
            show_usage();
            return 0;
        }
    }

    if (use_doubles) {
        run_doubles_test(c_file, gen_size);
    }
    else {
        run_test(c_file, a_file, b_file, gen_size);
    }
    return 0;
}
