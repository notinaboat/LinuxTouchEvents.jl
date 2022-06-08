PACKAGE := $(shell basename $(PWD))
export JULIA_PKG_OFFLINE = true
export JULIA_PROJECT = $(PWD)
export JULIA_DEPOT_PATH = $(CURDIR)/../jl_depot
export JULIA_NUM_THREADS = 8
export JULIA_DEBUG=loading
export JULIA_UNIX_IO_DEBUG_LEVEL = 4


all: README.md

JL := julia15

README.md: src/$(PACKAGE).jl
	julia --project -e "using $(PACKAGE); \
		                println($(PACKAGE).readme())" > $@

jl:
	$(JL) -i -e "using $(PACKAGE)"

jlenv:
	$(JL)
