
BINARY=stereo

BACON=bacon

CXXFLAGS=-g -Wall $(shell $(BACON) --ccflags) `pkg-config --cflags opencv`
LDFLAGS =$(shell $(BACON) --ldflags) `pkg-config --libs opencv`

BCS=$(shell ls *.bc)
BCOS=$(shell ls *.bc | perl -pe 's/\b(\w+)\.bc\b/\1.o/')
CCOS=$(shell ls *.cc | perl -pe 's/\b(\w+)\.cc\b/\1.o/')
OBJS=$(BCOS) $(CCOS)

#all:
#	@echo "skipping Stereo example"

$(BINARY): $(OBJS)
	$(CXX) -o $@ *.o $(LDFLAGS)

$(BCOS): %.o: %.bc Makefile
	$(BACON) $<
	(cd gen; make $@)
	(cd gen; make)
	cp gen/*.o .

$(CCOS): %.o: %.cc Makefile $(BCOS)

test: $(BINARY)
	./$(BINARY) -c t/disp5.png t/view1.png t/view5.png

profile: $(BINARY)
	sprofile -o prof.csv ./$(BINARY) -c t/disp5.png t/view1.png t/view5.png

cputest: $(BINARY)
	./$(BINARY) -c t/disp5.png -n t/view1.png t/view5.png

clean:
	rm -rf $(BINARY) *.o *~ gen prof.csv

.PHONY: clean test
