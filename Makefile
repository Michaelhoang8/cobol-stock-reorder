COBC ?= cobc
.PHONY: all test clean
all: stock-reorder
stock-reorder: src/reorder.cob
	$(COBC) -x -free -Wall -o $@ $<
test: stock-reorder
	python3 tests/test_reorder.py ./stock-reorder
clean:
	rm -f stock-reorder
