
BINARY=errors

BACON=../../bacon

CXXFLAGS=-g $(shell $(BACON) --ccflags)
LDFLAGS =$(shell $(BACON) --ldflags)

BCS=$(shell ls *.bc)
BCOS=$(shell ls *.bc | perl -pe 's/\b(\w+)\.bc\b/\1.o/')
CCOS=$(shell ls *.cc | perl -pe 's/\b(\w+)\.cc\b/\1.o/')
OBJS=$(BCOS) $(CCOS)

$(BINARY): $(OBJS)
	$(CXX) $(LDFLAGS) -o $@ *.o

$(BCOS): %.o: %.bc Makefile
	$(BACON) $<
	(cd gen; make $@)
	(cd gen; make)
	cp gen/*.o .

$(CCOS): %.o: %.cc Makefile $(BCOS)

test:
	echo "No tests ran. Try doing it manually."

clean:
	rm -rf $(BINARY) *.o *~ gen

.PHONY: clean test
