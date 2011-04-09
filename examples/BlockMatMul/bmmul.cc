
#include <fstream>
#include <iostream>
using std::cout;
using std::endl;

#include <string>
using std::string;

#include <stdlib.h>
#include <unistd.h>

#include "gen/BlockMatMul.hh"

void
run_test(string c_file, string a_file, string b_file, int block_size)
{
    BlockMatMul mmul;

    Bacon::Array2D<float> aa;
    Bacon::Array2D<float> bb;

    std::ifstream aaf(a_file.c_str());
    aa.read(&aaf);
    
    std::ifstream bbf(b_file.c_str());
    bb.read(&bbf);

    Bacon::Array2D<float> cc = mmul.blocked_mat_mul_private(aa, bb, block_size);

    if (c_file == "") {
        cc.write(&cout);
    }
    else {
        std::ofstream outf(c_file.c_str());
        cc.write(&outf);
    }
}

void
random_test(int nn, bool check, int block_size)
{
    BlockMatMul mmul;

    Bacon::Array2D<float> aa(nn, nn);
    aa.fill_random();

    Bacon::Array2D<float> bb(nn, nn);
    bb.fill_identity_matrix();

    cout << "Random test of " << nn << "x" << nn 
         << " matrices at block size = " << block_size << endl;

    Bacon::Array2D<float> cc = mmul.blocked_mat_mul_private(aa, bb, block_size);
   
    if(!check) {
        cout << "Result not checked." << endl;
        return;
    }
 
    if (array_equals_debug(aa, cc)) {
        cout << "Random test succeeded." << endl;
    }
    else {
        cout << "Random test failed, arrays don't match." << endl;
        std::ofstream aa_out("/tmp/aa.fail.txt");
        aa.write(&aa_out);
        std::ofstream bb_out("/tmp/bb.fail.txt");
        bb.write(&bb_out);
        std::ofstream cc_out("/tmp/cc.fail.txt");
        cc.write(&cc_out);
    }
}

void
show_usage()
{
    cout << "Usage: ./mmul [-o output -a matrix1 -b matrix2 | -n size] -k block_size" << endl;
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
    int block_size = 1;

    while ((opt = getopt(argc, argv, "ha:b:o:n:k:c")) != -1) {
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
        case 'k':
            block_size = atoi(optarg);
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
        random_test(random_size, check_result, block_size);
    }
    else {
        run_test(c_file, a_file, b_file, block_size);
    }

    return 0;
}
