#ifndef BACON_ERROR_HH
#define BACON_ERROR_HH

#define __CL_ENABLE_EXCEPTIONS 1
#include <CL/cl.hpp>

#include <exception>
#include <string>
#include <sstream>

namespace Bacon {

class Error : public std::exception {
  public:
    Error() 
    { 
        message = std::string("BaconError: Generic Error");
    }

    Error(const char* msg) 
    {
        message = std::string(msg);
    }

    Error(const char* msg, cl_long data) 
    {
        std::ostringstream tmp;
        tmp << msg << " (data = " << data << ")";
        message = tmp.str();
    }

    ~Error() throw()
    {
        // do nothing
    }

    virtual const char* what() const throw()
    { 
        return message.c_str(); 
    }

  private:
    std::string message;
};


} // namespace Bacon

#endif
