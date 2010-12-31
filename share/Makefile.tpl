
CL_INCDIR=$(shell perl paths.pl CL_INC)
CL_LIBDIR=$(shell perl paths.pl CL_LIB)

CC=$(CXX)
CXXFLAGS=-g -I $(CL_INCDIR)
LDFLAGS =-g -L $(CL_LIBDIR) -lOpenCL

OBJS=$(shell ls *.cc | perl -pe 's/\.cc\b/.o/')
HDRS=$(shell ls *.hh)

all: $(OBJS) test

$(OBJS): %.o: %.cc cl_perror.hh $(HDRS) Makefile

cl_perror.cc cl_perror.hh: cl_perror.pl Makefile
	perl cl_perror.pl $(CL_INCDIR)

test: $(OBJS) cl_perror.o

clean:
	rm -f *.o

.PHONY: all clean
