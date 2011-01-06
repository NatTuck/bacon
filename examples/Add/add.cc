
#include <iostream>
using std::cout;
using std::endl;

#include <string>
using std::string;

#include <unistd.h>

#include "gen/Bacon.hh"
#include "gen/Add.hh"
#include "gen/cl_perror.hh"

void
run_test(string c_file, string a_file, string b_file)
{
    Add adder;
    Bacon::Array2D<cl_int> aa(2,2);
    Bacon::Array2D<cl_int> bb(2,2);

    if (a_file == "") {
        aa.fill(1);
    }
    else {
        aa.read(a_file);        
    }

    if (b_file == "") {
        bb.fill(2);
    }
    else {
        bb.read(b_file);
    }
    
    Bacon::Array2D<cl_int> cc = adder.add(aa, bb);

    if (c_file == "") {
        cout << cc.to_string() << endl;
    }
    else {
        cc.write(c_file);
    }
}

int 
main(int argc, char* argv[])
{
    int opt;
    
    string a_file(""):
    string b_file("");
    string c_file(""); 

    while ((opt = getopt(argc, argv, "")) != -1) {
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
