// This file is generated automatically.
// Any changes you make will be lost.
    
#include <string>
using std::string;
    
#include <iostream>
using std::cerr;
using std::endl;
    
#include "cl_perror.hh"
    
string
cl_strerror(int code)
{
    switch (code) {
    case -1:
        return string("CL_BUILD_NONE");
    case -2:
        return string("CL_BUILD_ERROR");
    case -3:
        return string("CL_BUILD_IN_PROGRESS");
    case -4:
        return string("CL_MEM_OBJECT_ALLOCATION_FAILURE");
    case -5:
        return string("CL_OUT_OF_RESOURCES");
    case -6:
        return string("CL_OUT_OF_HOST_MEMORY");
    case -7:
        return string("CL_PROFILING_INFO_NOT_AVAILABLE");
    case -8:
        return string("CL_MEM_COPY_OVERLAP");
    case -9:
        return string("CL_IMAGE_FORMAT_MISMATCH");
    case -10:
        return string("CL_IMAGE_FORMAT_NOT_SUPPORTED");
    case -11:
        return string("CL_BUILD_PROGRAM_FAILURE");
    case -12:
        return string("CL_MAP_FAILURE");
    case -13:
        return string("CL_MISALIGNED_SUB_BUFFER_OFFSET");
    case -14:
        return string("CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST");
    case -30:
        return string("CL_INVALID_VALUE");
    case -31:
        return string("CL_INVALID_DEVICE_TYPE");
    case -32:
        return string("CL_INVALID_PLATFORM");
    case -33:
        return string("CL_INVALID_DEVICE");
    case -34:
        return string("CL_INVALID_CONTEXT");
    case -35:
        return string("CL_INVALID_QUEUE_PROPERTIES");
    case -36:
        return string("CL_INVALID_COMMAND_QUEUE");
    case -37:
        return string("CL_INVALID_HOST_PTR");
    case -38:
        return string("CL_INVALID_MEM_OBJECT");
    case -39:
        return string("CL_INVALID_IMAGE_FORMAT_DESCRIPTOR");
    case -40:
        return string("CL_INVALID_IMAGE_SIZE");
    case -41:
        return string("CL_INVALID_SAMPLER");
    case -42:
        return string("CL_INVALID_BINARY");
    case -43:
        return string("CL_INVALID_BUILD_OPTIONS");
    case -44:
        return string("CL_INVALID_PROGRAM");
    case -45:
        return string("CL_INVALID_PROGRAM_EXECUTABLE");
    case -46:
        return string("CL_INVALID_KERNEL_NAME");
    case -47:
        return string("CL_INVALID_KERNEL_DEFINITION");
    case -48:
        return string("CL_INVALID_KERNEL");
    case -49:
        return string("CL_INVALID_ARG_INDEX");
    case -50:
        return string("CL_INVALID_ARG_VALUE");
    case -51:
        return string("CL_INVALID_ARG_SIZE");
    case -52:
        return string("CL_INVALID_KERNEL_ARGS");
    case -53:
        return string("CL_INVALID_WORK_DIMENSION");
    case -54:
        return string("CL_INVALID_WORK_GROUP_SIZE");
    case -55:
        return string("CL_INVALID_WORK_ITEM_SIZE");
    case -56:
        return string("CL_INVALID_GLOBAL_OFFSET");
    case -57:
        return string("CL_INVALID_EVENT_WAIT_LIST");
    case -58:
        return string("CL_INVALID_EVENT");
    case -59:
        return string("CL_INVALID_OPERATION");
    case -60:
        return string("CL_INVALID_GL_OBJECT");
    case -61:
        return string("CL_INVALID_BUFFER_SIZE");
    case -62:
        return string("CL_INVALID_MIP_LEVEL");
    case -63:
        return string("CL_INVALID_GLOBAL_WORK_SIZE");
    default:
        return string("UNKNOWN_ERROR_CODE");
    };
}
    
void
cl_perror(int code)
{
    cerr << "OpenCL error: " << cl_strerror(code) << endl;
}
