#ifndef BACON_TIMER_HH
#define BACON_TIMER_HH

namespace Bacon {

#include <sys/time.h>

inline double 
time_nowf() 
{
    static const double M = 1000000.0;
    struct timeval tv;
    gettimeofday(&tv, 0);
    return double(tv.tv_sec) + (double(tv.tv_usec) / M);
}

class Timer {
  public:
    Timer() {
        this->reset();
    }

    inline void reset() {
        start = time_nowf();
    }
    
    inline double time() {
        double now = time_nowf();
        return now - start;
    }
    
  private:    
    double start;
};

} // namespace Bacon

#endif
