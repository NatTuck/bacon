
LIB=libbacon.so

BACON="../bin/bacon"

CC=$(CXX)
CXXFLAGS=-g -fPIC -Wall $(shell $(BACON) --ccflags) `perl -MExtUtils::Embed -e ccopts`
LDFLAGS=`perl -MExtUtils::Embed -e ldopts`
#LDFLAGS =-g $(shell $(BACON) --ldflags)

OBJS=$(shell ls *.cc | perl -pe 's/\.cc\b/.o/')
HDRS=$(shell ls ../include/*.hh)

all: $(LIB)

$(LIB): $(OBJS)
	$(CXX) $(LDFLAGS) -shared -o $(LIB) $(OBJS)

cl_perror.hh cl_perror.cc:
	$(BACON) --perror
	$(CXX) -c $(CXXFLAGS) -o cl_perror.o cl_perror.cc

$(OBJS): %.o: %.cc cl_perror.hh $(HDRS) Makefile

clean:
	rm -f $(LIB) *.o cl_perror.hh cl_perror.cc cl_perror.o *~

.PHONY: all clean
