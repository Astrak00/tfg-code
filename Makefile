# Configuration
RESULTS_DIR := $(CURDIR)/results
CORES := 14
SPHERE_DATA := sphere_data.txt

# Ensure results directory exists
$(RESULTS_DIR):
	@mkdir -p $(RESULTS_DIR)

# =============================================================================
# Helper Functions
# =============================================================================

# Generic function to run a ray tracer with timing
# Usage: $(call run_raytracer,directory,description,command,output_name)
define run_raytracer
	@echo "========================================="
	@echo "Running $(2)..."
	@echo "Command: $(3)"
	@echo "========================================="
	@cd $(1) && \
	{ time $(3) --output $(RESULTS_DIR)/$(4).ppm --cores $(CORES) --path ../$(SPHERE_DATA); } 2> $(RESULTS_DIR)/$(4).time
	@echo "$(2) completed successfully!"
	@echo ""
endef

# Function for single-threaded runs
# Usage: $(call run_raytracer_single,directory,description,command,output_name)
define run_raytracer_single
	@echo "========================================="
	@echo "Running $(2) (Single-threaded)..."
	@echo "Command: $(3)"
	@echo "========================================="
	@cd $(1) && \
	{ time $(3) --output ../$(RESULTS_DIR)/$(4).ppm --cores 1 ../$(SPHERE_DATA); } 2> ../$(RESULTS_DIR)/$(4).time
	@echo "$(2) completed successfully!"
	@tail -n 3 $(RESULTS_DIR)/$(4).time > $(RESULTS_DIR)/$(4).time.tmp && \
	mv $(RESULTS_DIR)/$(4).time.tmp $(RESULTS_DIR)/$(4).time
	@echo ""
endef

# =============================================================================
# Python Implementations
# =============================================================================

.PHONY: python python-single pypy pypy-single
python: $(RESULTS_DIR)
	$(call run_raytracer,python-Raytracer,Python Multi-threaded,python3 main.py,python-multi)

python-single: $(RESULTS_DIR)
	$(call run_raytracer_single,python-Raytracer,Python Single-threaded,python3 main.py,python-single)

pypy: $(RESULTS_DIR)
	@which pypy3 > /dev/null 2>&1 || { echo "Error: PyPy not found. Please install PyPy."; exit 1; }
	$(call run_raytracer,python-Raytracer,PyPy Multi-threaded,pypy3 main.py,pypy-multi)

pypy-single: $(RESULTS_DIR)
	@which pypy3 > /dev/null 2>&1 || { echo "Error: PyPy not found. Please install PyPy."; exit 1; }
	$(call run_raytracer_single,python-Raytracer,PyPy Single-threaded,pypy3 main.py,pypy-single)

# =============================================================================
# C++ Implementations
# =============================================================================

.PHONY: cpp cpp-single cpp-build
cpp-build:
	@echo "Building C++ ray tracer (Release mode with OpenMP)..."
	@cd cpp-RayTracer && \
	cmake -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_OPENMP=ON && \
	cmake --build build -j$(CORES)
	@echo "C++ build completed."

cpp: cpp-build $(RESULTS_DIR)
	$(call run_raytracer,cpp-RayTracer,C++ Multi-threaded,./build/inOneWeekend,cpp-multi)

cpp-single: cpp-build $(RESULTS_DIR)
	$(call run_raytracer_single,cpp-RayTracer,C++ Single-threaded,./build/inOneWeekend,cpp-single)

# =============================================================================
# Go Implementations
# =============================================================================

.PHONY: go go-single go-build
go-build:
	@echo "Building Go ray tracer..."
	@cd go-RayTracer && go build -o ray-tracer
	@echo "Go build completed."

go: go-build $(RESULTS_DIR)
	$(call run_raytracer,go-RayTracer,Go Multi-threaded,./ray-tracer,go-multi)

go-single: go-build $(RESULTS_DIR)
	$(call run_raytracer_single,go-RayTracer,Go Single-threaded,./ray-tracer,go-single)

# =============================================================================
# Rust Implementations
# =============================================================================

# .PHONY: rust rust-single rust-build
# rust-build:
# 	@echo "Building Rust ray tracer (Release mode)..."
# 	@cd rust-Raytracer && cargo build --release
# 	@echo "Rust build completed."

# rust: rust-build $(RESULTS_DIR)
# 	$(call run_raytracer,rust-Raytracer,Rust Multi-threaded,./target/release/ray-tracer,rust-multi)

# rust-single: rust-build $(RESULTS_DIR)
# 	$(call run_raytracer_single,rust-Raytracer,Rust Single-threaded,./target/release/ray-tracer,rust-single)

# =============================================================================
# Utility Targets
# =============================================================================

# .PHONY: ppm-diff
# ppm-diff:
# 	@echo "Building PPM difference tool..."
# 	@mkdir -p helpers/build
# 	@clang++ -std=c++11 -O2 helpers/ppm_diff.cpp -o helpers/build/ppm_diff
# 	@echo "PPM difference tool built: helpers/build/ppm_diff"
# 	@echo "Usage: helpers/build/ppm_diff <file1.ppm> <file2.ppm>"

# =============================================================================
# Batch Operations
# =============================================================================

.PHONY: all all-multi all-single benchmark
all-multi: cpp go pypy # rustpython
	@echo ""
	@echo "========================================="
	@echo "All multi-threaded implementations completed!"
	@echo "========================================="
	@echo "Generated images and timing data:"
	@ls -lh $(RESULTS_DIR)/*.ppm 2>/dev/null || echo "No PPM files found"
	@ls -lh $(RESULTS_DIR)/*.time 2>/dev/null || echo "No timing files found"

all-single: cpp-single go-single python-single pypy-single # rust-single
	@echo ""
	@echo "========================================="
	@echo "All single-threaded implementations completed!"
	@echo "========================================="
	@echo "Generated images and timing data:"
	@ls -lh $(RESULTS_DIR)/*.ppm 2>/dev/null || echo "No PPM files found"
	@ls -lh $(RESULTS_DIR)/*.time 2>/dev/null || echo "No timing files found"

all: all-multi all-single
	@echo ""
	@echo "========================================="
	@echo "Complete benchmark suite finished!"
	@echo "========================================="

benchmark: all
	@echo "Performance comparison ready!"
	@echo "Check $(RESULTS_DIR)/ for results."

# =============================================================================
# Cleanup
# =============================================================================

.PHONY: clean clean-builds clean-all
clean:
	@echo "Cleaning results..."
	@rm -rf $(RESULTS_DIR)/*.ppm $(RESULTS_DIR)/*.time 2>/dev/null || true
	@echo "Results cleaned."

clean-builds:
	@echo "Cleaning build artifacts..."
	@rm -rf cpp-RayTracer/build* || true
	@rm -rf go-RayTracer/ray-tracer || true
	@rm -rf helpers/build || true
	@echo "Build artifacts cleaned."

clean-all: clean clean-builds
	@echo "Full cleanup completed."

# =============================================================================
# Help and Information
# =============================================================================

.PHONY: help info
help:
	@echo "Ray Tracer Performance Comparison Makefile"
	@echo ""
	@echo "Individual Language Targets:"
	@echo "  python        - Run Python multi-threaded implementation"
	@echo "  python-single - Run Python single-threaded implementation"
	@echo "  pypy          - Run PyPy multi-threaded implementation"
	@echo "  pypy-single   - Run PyPy single-threaded implementation"
	@echo "  cpp           - Build and run C++ multi-threaded implementation"
	@echo "  cpp-single    - Build and run C++ single-threaded implementation"
	@echo "  go            - Build and run Go multi-threaded implementation"
	@echo "  go-single     - Build and run Go single-threaded implementation"
	@echo ""
	@echo "Batch Targets:"
	@echo "  all-multi     - Run all multi-threaded implementations"
	@echo "  all-single    - Run all single-threaded implementations"
	@echo "  all           - Run complete benchmark suite"
	@echo "  benchmark     - Alias for 'all'"
	@echo ""
	@echo "Utility Targets:"
	@echo "  ppm-diff      - Build PPM comparison tool"
	@echo "  clean         - Remove generated results"
	@echo "  clean-builds  - Remove build artifacts"
	@echo "  clean-all     - Remove results and build artifacts"
	@echo "  help          - Show this help message"
	@echo "  info          - Show current configuration"

info:
	@echo "Current Configuration:"
	@echo "  Results Directory: $(RESULTS_DIR)"
	@echo "  CPU Cores:         $(CORES)"
	@echo "  Sphere Data:       $(SPHERE_DATA)"
	@echo "  Current Directory: $(CURDIR)"

# Default target
.DEFAULT_GOAL := help