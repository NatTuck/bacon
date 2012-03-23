
#include <cstdio>
#include <iostream>
#include <unistd.h>

#include "gen/NasEP.hh"


void
run_chunks()
{
    const int SIZE = 10;
    NasEP ep;

    Bacon::Array<double> cc = ep.chunks(SIZE);

    for (int ii = 0; ii < SIZE; ++ii) {
        printf("%.02f\n", cc.get(ii));
    }
}

void
run_class_a(bool approx)
{
    const int SIZE = 2048;
    NasEP ep;

    Bacon::Array2D<double> cc = ep.class_a(SIZE);

    //cc.write(&std::cout);
    //printf("\n");

    double sumX = 0.0;
    double sumY = 0.0;

    for (int jj = 0; jj < SIZE; ++jj) {
        sumX += cc.get(10, jj);
        sumY += cc.get(11, jj);
    }

    if (approx) {
        printf("SumX\t%.06e\n", sumX);
        printf("SumY\t%.06e\n", sumY);
    }
    else {
        printf("SumX\t%.014e\n", sumX);
        printf("SumY\t%.014e\n", sumY);
    }

    printf("\n");

    for (int ii = 0; ii < 10; ++ii) {
        double sum = 0.0;

        for (int jj = 0; jj < SIZE; ++jj) {
            sum += cc.get(ii, jj);
        }

        printf(" %d\t%f\n", ii, sum);
    }

}

int 
main(int argc, char* argv[])
{
    int opt;
    bool do_chunks = false;
    bool do_approx = false;

    while ((opt = getopt(argc, argv, "ac")) != -1) {
        switch(opt) {
        case 'a':
            do_approx = true;
            break;
        case 'c':
            do_chunks = true;
            break;
        }
    }

    if (do_chunks) {
        run_chunks();
    }
    else {
        run_class_a(do_approx);
    }
    return 0;
}
