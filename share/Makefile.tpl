
CC=$(CXX)
CXXFLAGS=-g <% $CCFLAGS %>
LDFLAGS =-g <% $LDFLAGS %>

OBJS=$(shell ls *.cc | perl -pe 's/\.cc\b/.o/')
HDRS=$(shell ls *.hh)

all: $(OBJS)

$(OBJS): %.o: %.cc $(HDRS) Makefile

clean:
	rm -f *.o

.PHONY: all clean
