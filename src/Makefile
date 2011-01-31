
LIB=libbacon.so

BACON="../bacon"

CC=$(CXX)
CXXFLAGS=-g -fPIC $(shell $(BACON) --ccflags)
LDFLAGS =-g $(shell (BACON) --ldflags)

OBJS=$(shell ls *.cc | perl -pe 's/\.cc\b/.o/')
HDRS=$(shell ls ../include/*.hh)

all: $(LIB)

$(LIB): $(OBJS)
	$(CXX) -shared -o $(LIB) $(OBJS)

cl_perror.hh cl_perror.cc:
	$(BACON) --perror

$(OBJS): %.o: %.cc cl_perror.hh $(HDRS) Makefile


clean:
	rm -f $(LIB) *.o cl_perror.hh cl_perror.o *~

.PHONY: all clean
