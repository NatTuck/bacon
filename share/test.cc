
#include <iostream>
using std::cout;
using std::endl;

#include "Bacon.hh"
#include "Add.hh"
#include "cl_perror.hh"

void
run_test()
{
    Add adder;
    Bacon::Array2D<cl_int> aa(2,2);
    Bacon::Array2D<cl_int> bb(2,2);

    aa.fill(1);
    bb.fill(2);

    Bacon::Array2D<cl_int> cc = adder.add(aa, bb);

    cout << cc.get(0, 0) << " " << cc.get(0, 1) << endl;
    cout << cc.get(1, 0) << " " << cc.get(1, 1) << endl;
}

int 
main(int argc, char* argv[])
{
    try {
        run_test();
    }
    catch(cl::Error ee) {
        cout << "Got error:\n";
        cout << " what: " << ee.what() << endl;
        cl_perror(ee.err());
    }
    return 0;
}
