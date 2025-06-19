# =============================================================================
# Ray Tracer Performance Comparison Makefile
# =============================================================================

# Configuration
CORES                 ?= 14
MAC_OS                ?= False
SERVER 		      ?= False
RESULTS_DIR           := $(CURDIR)/results-$(CORES)
SPHERE_DATA           := sphere_data.txt
POWERMETRICS_PID_FILE := $(RESULTS_DIR)/power/powermetrics.pid
POWER_LOG             := $(RESULTS_DIR)/power/powermetrics
POWER_TRIMM_LOG       := $(RESULTS_DIR)/power/powermetrics_trimmed
POWER_CLEANED_LOG     := $(RESULTS_DIR)/power/powermetrics_cleaned
POWER_INTERVAL        := 100  # Interval in milliseconds for powermetrics

# Performance measurement commands
ifeq ($(MAC_OS),True)
    PERF_COMMAND := date +%H:%M:%S::%M; time
else
    PERF_COMMAND := perf stat -r 5 -e 'power/energy-pkg/,power/energy-ram/'
endif

ifeq ($(SERVER), True)
	# Adjust PERF_COMMAND based on core count
	ifeq ($(shell [ $(CORES) -le 16 ] && echo true),true)
	       PERF_COMMAND := $(PERF_COMMAND) taskset -c 0-15
	else ifeq ($(shell [ $(CORES) -le 32 ] && echo true),true)
	       #PERF_COMMAND := $(PERF_COMMAND) taskset -c 0-31
	       PERF_COMMAND := $(PERF_COMMAND) taskset -c 0-15,32-47
	else ifeq ($(shell [ $(CORES) -le 48 ] && echo true),true)
	        PERF_COMMAND := $(PERF_COMMAND) taskset -c 0-47
	#else 
	#	PERF_COMMAND := $(PERF_COMMAND) taskset -c 0-59
	endif
endif
	



# =============================================================================
# Directory Setup
# =============================================================================

$(RESULTS_DIR):
	@mkdir -p $(RESULTS_DIR)

# =============================================================================
# Power Management Functions
# =============================================================================

# Args: $(1)=output_name
define start_powermetrics
	@if [ "$(MAC_OS)" = "True" ]; then \
		echo "Starting power metrics collection..."; \
		if ! sudo -n true 2>/dev/null; then \
			echo "This operation requires sudo access for powermetrics."; \
			echo "Please run this program as sudo:"; \
			exit 1; \
		fi; \
		mkdir -p $(RESULTS_DIR)/power; \
		sudo powermetrics -i $(POWER_INTERVAL) \
			--samplers cpu_power \
			--hide-cpu-duty-cycle \
			> $(POWER_LOG)_$(1).log 2>&1 & \
		echo $$! > $(POWERMETRICS_PID_FILE); \
		echo "Power metrics started with PID $$(cat $(POWERMETRICS_PID_FILE))"; \
		sleep 2; \
	fi
endef

# Args: $(1)=output_name
define stop_powermetrics
	@if [ "$(MAC_OS)" = "True" ] && [ -f $(POWERMETRICS_PID_FILE) ]; then \
		echo "Stopping power metrics collection..."; \
		sudo kill $$(cat $(POWERMETRICS_PID_FILE)) 2>/dev/null || true; \
		rm -f $(POWERMETRICS_PID_FILE); \
		echo "Power metrics collection stopped"; \
	fi
	@if [ "$(MAC_OS)" = "True" ] && [ -f $(POWER_LOG)_$(1).log ]; then \
		echo "Processing power log with start time..."; \
		if [ -f $(RESULTS_DIR)/$(1)_start_time.txt ]; then \
			start_time=$$(cat $(RESULTS_DIR)/$(1)_start_time.txt); \
			sed -n "/$$start_time/,\$$p" $(POWER_LOG)_$(1).log > $(POWER_TRIMM_LOG)_$(1).log; \
		else \
			echo "Start time file not found, using entire log"; \
			cp $(POWER_LOG) $(POWER_TRIMM_LOG)_$(1).log; \
		fi; \
	fi
	@if [ "$(MAC_OS)" = "True" ] && [ -f $(POWER_TRIMM_LOG)_$(1).log ]; then \
		echo "Cleaning power metrics data..."; \
		grep "CPU Power:" $(POWER_TRIMM_LOG)_$(1).log | \
			awk '{print $$3}' > $(POWER_CLEANED_LOG)_$(1).log; \
		echo "Cleaned data saved to $(POWER_CLEANED_LOG)_$(1).log"; \
	else \
		if [ "$(MAC_OS)" = "True" ]; then \
			echo "No power metrics log found or not on Mac OS"; \
		fi; \
	fi
endef

# =============================================================================
# Ray Tracer Execution Functions
# =============================================================================

# Generic function to run a ray tracer with timing
# Args: $(1)=directory, $(2)=description, $(3)=command, $(4)=output_name
define run_raytracer
	@echo ""
	@echo "Running $(2)..."
	@echo "Directory: $(1)"
	@echo "Command:   $(3)"
	@echo "Cores:     $(CORES)"
	@echo "========================================="
	@start_time=$$(date +%H:%M:%S); \
	cd $(1) && { \
		$(PERF_COMMAND) $(3) \
			--output $(RESULTS_DIR)/$(4).ppm \
			--cores $(CORES) \
			--path ../$(SPHERE_DATA); \
	} 2> $(RESULTS_DIR)/$(4).perf; \
	end_time=$$(date +%H:%M:%S); \
	echo "\n$(2) completed successfully!"; \
	if [ "$(MAC_OS)" = "True" ]; then \
		echo "$$start_time" > $(RESULTS_DIR)/$(4)_start_time.txt; \
		echo "$$end_time" > $(RESULTS_DIR)/$(4)_end_time.txt; \
	fi;
endef

# Single-threaded version
# Args: $(1)=directory, $(2)=description, $(3)=command, $(4)=output_name
define run_raytracer_single
	@echo ""
	@echo "Running $(2)..."
	@echo "Directory: $(1)"
	@echo "Command:   $(3)"
	@echo "Cores:     1"
	@echo "========================================="
	@start_time=$$(date +%H:%M:%S); \
	cd $(1) && { \
		$(PERF_COMMAND) $(3) \
			--output $(RESULTS_DIR)/$(4).ppm \
			--cores 1 \
			--path ../$(SPHERE_DATA); \
	} 2> $(RESULTS_DIR)/$(4).perf; \
	end_time=$$(date +%H:%M:%S); \
	echo "$(2) completed successfully!"; \
	if [ "$(MAC_OS)" = "True" ]; then \
		echo "$$start_time" > $(RESULTS_DIR)/$(4)_start_time.txt; \
		echo "$$end_time" > $(RESULTS_DIR)/$(4)_end_time.txt; \
	fi;
endef

# =============================================================================
# Build Functions
# =============================================================================

define build_cpp
	@echo "Building C++ ray tracer (Release mode with OpenMP)..."
	@cd cpp-RayTracer && \
		cmake -B build \
			-DCMAKE_BUILD_TYPE=Release \
			-DENABLE_OPENMP=ON && \
		cmake --build build -j$(CORES)
	@echo "C++ build completed"
endef

define build_go
	@echo "Building Go ray tracer..."
	@cd go-RayTracer && go build -o ray-tracer
	@echo "Go build completed"
endef



# =============================================================================
# Language-Specific Targets
# =============================================================================

# Python Implementations
.PHONY: python python-single pypy pypy-single

python: $(RESULTS_DIR)
	$(call start_powermetrics,python-multi)
	$(call run_raytracer,python-Raytracer,Python Multi-threaded,python3 main.py,python-multi)
	$(call stop_powermetrics,python-multi)

python-single: $(RESULTS_DIR)
	$(call start_powermetrics,python-single)
	$(call run_raytracer_single,python-Raytracer,Python Single-threaded,python3 main.py,python-single)
	$(call stop_powermetrics,python-single)

pypy: $(RESULTS_DIR)
	@which pypy3 > /dev/null 2>&1 || { \
		echo "Error: PyPy not found. Please install PyPy."; \
		exit 1; \
	}
	$(call start_powermetrics,pypy-multi)
	$(call run_raytracer,python-Raytracer,PyPy Multi-threaded,pypy3 main.py,pypy-multi)
	$(call stop_powermetrics,pypy-multi)

pypy-single: $(RESULTS_DIR)
	@which pypy3 > /dev/null 2>&1 || { \
		echo "Error: PyPy not found. Please install PyPy."; \
		exit 1; \
	}
	$(call start_powermetrics,pypy-single)
	$(call run_raytracer_single,python-Raytracer,PyPy Single-threaded,pypy3 main.py,pypy-single)
	$(call stop_powermetrics,pypy-single)

# C++ Implementations
.PHONY: cpp cpp-single cpp-build

cpp-build:
	$(call build_cpp)

cpp: cpp-build $(RESULTS_DIR)
	$(call start_powermetrics,cpp-multi)
	$(call run_raytracer,cpp-RayTracer,C++ Multi-threaded,./build/raytracer,cpp-multi)
	$(call stop_powermetrics,cpp-multi)

cpp-single: cpp-build $(RESULTS_DIR)
	$(call start_powermetrics,cpp-single)
	$(call run_raytracer_single,cpp-RayTracer,C++ Single-threaded,./build/raytracer,cpp-single)
	$(call stop_powermetrics,cpp-single)

# Go Implementations
.PHONY: go go-single go-build

go-build:
	$(call build_go)

go: go-build $(RESULTS_DIR)
	@echo $(PERF_COMMAND)
	$(call start_powermetrics,go-multi)
	$(call run_raytracer,go-RayTracer,Go Multi-threaded,./ray-tracer,go-multi)
	$(call stop_powermetrics,go-multi)

go-single: go-build $(RESULTS_DIR)
	$(call start_powermetrics,go-single)
	$(call run_raytracer_single,go-RayTracer,Go Single-threaded,./ray-tracer,go-single)
	$(call stop_powermetrics,go-single)

# Rust Implementations
# .PHONY: rust rust-single rust-build
# 
# rust-build:
# 	@echo "Building Rust ray tracer (Release mode)..."
# 	@cd rust-Raytracer && cargo build --release
# 	@echo "Rust build completed"

# rust: rust-build $(RESULTS_DIR)
# 	$(call start_powermetrics)
# 	$(call run_raytracer,rust-Raytracer,Rust Multi-threaded,./target/release/ray-tracer,rust-multi)
# 	$(call stop_powermetrics,rust-multi)


# rust-single: rust-build $(RESULTS_DIR)
# 	$(call start_powermetrics)
# 	$(call run_raytracer_single,rust-Raytracer,Rust Single-threaded,./target/release/ray-tracer,rust-single)
# 	$(call stop_powermetrics,rust-single)


# =============================================================================
# Batch Operations
# =============================================================================

.PHONY: all all-multi all-single benchmark

all-multi: cpp go pypy python $(RESULTS_DIR)
	@echo ""
	@echo "========================================="
	@echo "All multi-threaded implementations completed!"
	@echo "========================================="
	@echo "Generated files:"
	@ls -lh $(RESULTS_DIR)/*.ppm 2>/dev/null || echo "   No PPM files found"
	@ls -lh $(RESULTS_DIR)/*.perf 2>/dev/null || echo "   No performance files found"

all-single: cpp-single go-single pypy-single python-single $(RESULTS_DIR)
	@echo ""
	@echo "========================================="
	@echo "All single-threaded implementations completed!"
	@echo "========================================="	@echo "📊 Generated files:"
	@ls -lh $(RESULTS_DIR)/*.ppm 2>/dev/null || echo "   No PPM files found"
	@ls -lh $(RESULTS_DIR)/*.perf 2>/dev/null || echo "   No performance files found"

all: all-multi all-single
	@echo ""
	@echo "Complete benchmark suite finished!"
	@echo "Results available in: $(RESULTS_DIR)/"

benchmark: all
	@echo "Performance comparison ready!"
	@echo "Check $(RESULTS_DIR)/ for detailed results"

# =============================================================================
# Utility Targets
# =============================================================================

.PHONY: ppm-diff clean-power

ppm-diff:
	@echo "Building PPM difference tool..."
	@mkdir -p helpers/build
	@clang++ -std=c++11 -O2 helpers/ppm_diff.cpp -o helpers/build/ppm_diff
	@echo "PPM difference tool built: helpers/build/ppm_diff"
	@echo "Usage: helpers/build/ppm_diff <file1.ppm> <file2.ppm>"

clean-power:
	@if [ "$(MAC_OS)" = "True" ] && [ -f $(POWER_LOG) ]; then \
		echo "Cleaning power metrics log..."; \
		cat $(POWER_LOG) | \
			grep "CPU Power:" | \
			awk '{print $$3}' > $(POWER_CLEANED_LOG); \
		echo "Cleaned data saved to $(POWER_CLEANED_LOG)"; \
	else \
		echo "No power metrics log found or not on Mac OS"; \
	fi

# =============================================================================
# Cleanup Targets
# =============================================================================

.PHONY: clean clean-builds clean-all stop-power

stop-power:
	$(call,stop-power stop_powermetrics,manual)

clean:
	@echo "Cleaning results..."
	$(call stop_powermetrics,clean)
	@rm -rf $(RESULTS_DIR)/*.ppm $(RESULTS_DIR)/*.time $(RESULTS_DIR)/*.perf 2>/dev/null || true
	@rm -rf $(RESULTS_DIR)/power 2>/dev/null || true
	@echo "Results cleaned"

clean-builds:
	@echo "Cleaning build artifacts..."
	@rm -rf cpp-RayTracer/build* || true
	@rm -rf go-RayTracer/ray-tracer || true
	@rm -rf helpers/build || true
	@echo "Build artifacts cleaned"

clean-all: clean clean-builds
	@echo "Full cleanup completed"

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
	@echo "Build Targets:"
	@echo "  cpp-build     - Build C++ implementation only"
	@echo "  go-build      - Build Go implementation only"
	@echo ""
	@echo "Utility Targets:"
	@echo "  ppm-diff      - Build PPM comparison tool"
	@echo "  clean-power   - Clean and process power metrics log"
	@echo "  stop-power    - Stop any running powermetrics process"
	@echo ""
	@echo "Cleanup Targets:"
	@echo "  clean         - Remove generated results"
	@echo "  clean-builds  - Remove build artifacts"
	@echo "  clean-all     - Remove results and build artifacts"
	@echo ""
	@echo "Information:"
	@echo "  help          - Show this help message"
	@echo "  info          - Show current configuration"

info:
	@echo "Current Configuration:"
	@echo "  Results Directory: $(RESULTS_DIR)"
	@echo "  CPU Cores:         $(CORES)"
	@echo "  Sphere Data:       $(SPHERE_DATA)"
	@echo "  Current Directory: $(CURDIR)"
	@echo "  Power Log:         $(POWER_LOG)"
	@echo "  Cleaned Power Log: $(POWER_CLEANED_LOG)"
	@echo "  Mac OS Mode:       $(MAC_OS)"
	@echo "  Performance Tool:  $(PERF_COMMAND)"

# Default target
.DEFAULT_GOAL := help
