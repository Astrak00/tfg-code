EXE=cuda-raytracer

# Compiler
NVCC=/usr/local/cuda/bin/nvcc

# Check if NVCC exists
ifneq ($(shell which $(NVCC) 2>/dev/null),)
  NVCC_EXISTS=true
else
  NVCC_EXISTS=false
endif

# Compiler flags
NVCC_FLAGS=-O3 -std=c++11 -arch=sm_70

# Source files
SRC=src/main.cu

# Object files
OBJ=$(SRC:.cu=.o)

.PHONY: all clean

all: $(EXE)

$(EXE): $(OBJ)
ifeq ($(NVCC_EXISTS),true)
	$(NVCC) $(NVCC_FLAGS) -o $@ $^
else
	@echo "Error: nvcc not found. Please install the CUDA toolkit."
	@exit 1
endif

%.o: %.cu
ifeq ($(NVCC_EXISTS),true)
	$(NVCC) $(NVCC_FLAGS) -c -o $@ $<
else
	@echo "Error: nvcc not found. Please install the CUDA toolkit."
	@exit 1
endif

clean:
	rm -f $(EXE) $(OBJ)