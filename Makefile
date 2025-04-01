# Directories
RESULTS_DIR=$(CURDIR)/results

# Helper function to run a ray tracer
define run_trace
	bash -c '\
		mkdir -p $(RESULTS_DIR); \
		cd $(1) > /dev/null; \
		echo "Running $(2) with command $(3)..." && \
		{ time $(3) --path ../sphere_data.txt > $(RESULTS_DIR)/$(4).ppm; } 2> $(RESULTS_DIR)/$(4).time; \
		echo "Running $(2) with command $(3) completed." && \
		tail -n 3 $(RESULTS_DIR)/$(4).time > $(RESULTS_DIR)/$(4).time.tmp && mv $(RESULTS_DIR)/$(4).time.tmp $(RESULTS_DIR)/$(4).time; \
		cd - > /dev/null \
	'
endef

# Python implementations
python:
	$(call run_trace,python-RayTracer,Python,MULTITHREADING=1 python3 main.py,py-RayTracer)

python-multi:
	$(call run_trace,python-RayTracer,Python Multi,python3 main.py,py-multi-RayTracer)

pypy:
	bash -c 'which pypy > /dev/null 2>&1 || (echo "Error: PyPy not found. Please install PyPy or make sure it'\''s in your PATH." && exit 1)'
	$(call run_trace,python-RayTracer,PyPy,MULTITHREADING=1 pypy main.py,pypy-RayTracer)

pypy-multi:
	bash -c 'which pypy > /dev/null 2>&1 || (echo "Error: PyPy not found. Please install PyPy or make sure it'\''s in your PATH." && exit 1)'
	$(call run_trace,python-RayTracer,PyPy Multi,pypy main.py,pypy-multi-RayTracer)

# C++ implementations
cpp:
	bash -c '\
		pushd cpp-RayTracer > /dev/null; \
		cmake -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_OPENMP=OFF && cmake --build build -j; \
		popd > /dev/null \
	'
	$(call run_trace,cpp-RayTracer,C++,./build/inOneWeekend,cpp-RayTracer)

cpp-multi:
	bash -c '\
		pushd cpp-RayTracer > /dev/null; \
		cmake -B build-multi -DCMAKE_BUILD_TYPE=Release -DENABLE_OPENMP=ON && cmake --build build-multi -j; \
		popd > /dev/null \
	'
	$(call run_trace,cpp-RayTracer,C++ Multi,./build-multi/inOneWeekend --cores 10,cpp-multi-RayTracer)

# Go implementations
go:
	bash -c 'pushd go-RayTracer > /dev/null && go build -o ray-tracer && popd > /dev/null'
	$(call run_trace,go-RayTracer,Go,MULTITHREADING=1 ./ray-tracer,go-RayTracer)

go-multi:
	bash -c 'pushd go-RayTracer > /dev/null && go build -o ray-tracer && popd > /dev/null'
	$(call run_trace,go-RayTracer,Go Multi,"./ray-tracer",go-multi-RayTracer)

# Rust implementation
rust:
	bash -c 'pushd rust-RayTracer > /dev/null && cargo build --release && popd > /dev/null'
	$(call run_trace,rust-RayTracer,Rust,./target/release/ray-tracer,rust-RayTracer)

# PPM difference tool
ppm-diff:
	@mkdir -p helpers/build
	@clang++ -std=c++11 -O2 helpers/ppm_diff.cpp -o helpers/build/ppm_diff
	@echo "PPM difference tool built: helpers/build/ppm_diff"
	@echo "Usage: helpers/build/ppm_diff <file1.ppm> <file2.ppm>"

# Run all implementations
all:
	@echo "Running all implementations..."
	@echo "Running multicore implementations..."
	@$(MAKE) go-multi
	@$(MAKE) cpp-multi
	@$(MAKE) rust
	@echo "Running singlecore implementation..."
	@$(MAKE) cpp
	@$(MAKE) go
	@echo "Running *PyPy* implementation..."
	@$(MAKE) pypy
	@$(MAKE) pypy-multi
	@echo "Running *Python* implementation..."
	@$(MAKE) python
	@$(MAKE) python-multi

	@echo "All implementations completed."
	@echo "Generated images:"
	@ls -lh $(RESULTS_DIR)/*.ppm
	@echo "You can view the images using an image viewer."

# Clean results
clean:
	@echo "Cleaning up..."
	@rm -f $(RESULTS_DIR)/*.ppm
	@rm -f $(RESULTS_DIR)/*.time
	@echo "Cleaned up."
