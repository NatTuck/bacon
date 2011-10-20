
BINARY=bmmul

BACON=bacon

CXXFLAGS=-g -Wall $(shell $(BACON) --ccflags)
LDFLAGS =$(shell $(BACON) --ldflags)

BCS=$(shell ls *.bc)
BCOS=$(shell ls *.bc | perl -pe 's/\b(\w+)\.bc\b/\1.o/')
CCOS=$(shell ls *.cc | perl -pe 's/\b(\w+)\.cc\b/\1.o/')
OBJS=$(BCOS) $(CCOS)

$(BINARY): $(OBJS)
	$(CXX) -o $@ *.o $(LDFLAGS)

$(BCOS): %.o: %.bc Makefile
	$(BACON) $<
	(cd gen; make $@)
	(cd gen; make)
	cp gen/*.o .

$(CCOS): %.o: %.cc Makefile $(BCOS)

test: $(BINARY)
	(cd ../.. && prove examples/BlockMatMul/t/*.t)

clean:
	rm -rf $(BINARY) *.o *~ gen

.PHONY: clean test
