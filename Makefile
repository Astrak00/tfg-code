python:
	cd python-RayTracer && \
	{ time python3 main.py > ../results/py-RayTracer.ppm; } 2> ../results/py-RayTracer.time && \
	tail -n 3 ../results/py-RayTracer.time > ../results/py-RayTracer.time.tmp && mv ../results/py-RayTracer.time.tmp ../results/py-RayTracer.time && \
	cd ..

python-multi:
	cd python-RayTracer && \
	{ time MULTITHREADING=1 python3 main.py > ../results/py-multi-RayTracer.ppm; } 2> ../results/py-multi-RayTracer.time && \
	tail -n 3 ../results/py-multi-RayTracer.time > ../results/py-multi-RayTracer.time.tmp && mv ../results/py-multi-RayTracer.time.tmp ../results/py-multi-RayTracer.time && \
	cd ..

pypy:
	cd python-RayTracer && \
	{ time pypy main.py > ../results/pypy-RayTracer.ppm; } 2> ../results/pypy-RayTracer.time && \
	tail -n 3 ../results/pypy-RayTracer.time > ../results/pypy-RayTracer.time.tmp && mv ../results/pypy-RayTracer.time.tmp ../results/pypy-RayTracer.time && \
	cd ..

pypy-multi:
	cd python-RayTracer && \
	{ time MULTITHREADING=1 pypy main.py > ../results/pypy-multi-RayTracer.ppm; } 2> ../results/pypy-multi-RayTracer.time && \
	tail -n 3 ../results/pypy-multi-RayTracer.time > ../results/pypy-multi-RayTracer.time.tmp && mv ../results/pypy-multi-RayTracer.time.tmp ../results/pypy-multi-RayTracer.time && \
	cd ..

cpp:
	cd cpp-RayTracer && \
	cmake -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_OPENMP=OFF && cmake --build build -j && \
	echo "Running C++ Ray Tracer..." && \
	{ time ./build/inOneWeekend > ../results/cpp-RayTracer.ppm; } 2> ../results/cpp-RayTracer.time && \
	tail -n 3 ../results/cpp-RayTracer.time > ../results/cpp-RayTracer.time.tmp && mv ../results/cpp-RayTracer.time.tmp ../results/cpp-RayTracer.time && \
	cd ..

cpp-multi:
	cd cpp-RayTracer && \
	cmake -B build-multi -DCMAKE_BUILD_TYPE=Release -DENABLE_OPENMP=ON && cmake --build build-multi -j && \
	echo "Running C++ Ray Tracer..." && \
	{ time ./build-multi/inOneWeekend > ../results/cpp-multi-RayTracer.ppm; } 2> ../results/cpp-multi-RayTracer.time && \
	tail -n 3 ../results/cpp-multi-RayTracer.time > ../results/cpp-multi-RayTracer.time.tmp && mv ../results/cpp-multi-RayTracer.time.tmp ../results/cpp-multi-RayTracer.time && \
	cd ..

go:
	cd go-RayTracer && \
	go build && \
	{ time ./ray-tracer > ../results/go-RayTracer.ppm; } 2> ../results/go-RayTracer.time && \
	tail -n 3 ../results/go-RayTracer.time > ../results/go-RayTracer.time.tmp && mv ../results/go-RayTracer.time.tmp ../results/go-RayTracer.time && \
	cd ..

go-multi:
	cd go-RayTracer && \
	go build -o ray-tracer-multi -tags openmp && \
	{ time MULTITHREADING=1 ./ray-tracer-multi > ../results/go-multi-RayTracer.ppm; } 2> ../results/go-multi-RayTracer.time && \
	tail -n 3 ../results/go-multi-RayTracer.time > ../results/go-multi-RayTracer.time.tmp && mv ../results/go-multi-RayTracer.time.tmp ../results/go-multi-RayTracer.time && \
	cd ..

rust:
	cd rust-RayTracer && \
	cargo build --release && \
	{ time ./target/release/ray-tracer > ../results/rust-RayTracer.ppm; } 2> ../results/rust-RayTracer.time && \
	tail -n 3 ../results/rust-RayTracer.time > ../results/rust-RayTracer.time.tmp && mv ../results/rust-RayTracer.time.tmp ../results/rust-RayTracer.time && \
	cd ..

ppm-diff:
	@mkdir -p helpers/build
	g++ -std=c++11 -O2 helpers/ppm_diff.cpp -o helpers/build/ppm_diff
	@echo "PPM difference tool built: helpers/build/ppm_diff"
	@echo "Usage: helpers/build/ppm_diff <file1.ppm> <file2.ppm>"

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
	@ls -lh *.ppm
	@echo "You can view the images using an image viewer."

clean:
	@echo "Cleaning up..."
	@rm -f results/*.ppm 
	@rm -f results/*.time
	@echo "Cleaned up."