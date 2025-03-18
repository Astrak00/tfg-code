python:
	cd python-RayTracer && \
	{ time python3 main.py > ../py-RayTracer.ppm; } 2> ../py-RayTracer.time && \
	tail -n 4 ../py-RayTracer.time > ../py-RayTracer.time.tmp && mv ../py-RayTracer.time.tmp ../py-RayTracer.time && \
	cd ..

python-multi:
	cd python-RayTracer && \
	{ time MULTITHREADING=1 python3 main.py > ../py-multi-RayTracer.ppm; } 2> ../py-multi-RayTracer.time && \
	tail -n 4 ../py-multi-RayTracer.time > ../py-multi-RayTracer.time.tmp && mv ../py-multi-RayTracer.time.tmp ../py-multi-RayTracer.time && \
	cd ..

pypy:
	cd python-RayTracer && \
	{ time pypy main.py > ../pypy-RayTracer.ppm; } 2> ../pypy-RayTracer.time && \
	tail -n 4 ../pypy-RayTracer.time > ../pypy-RayTracer.time.tmp && mv ../pypy-RayTracer.time.tmp ../pypy-RayTracer.time && \
	cd ..

pypy-multi:
	cd python-RayTracer && \
	{ time MULTITHREADING=1 pypy main.py > ../pypy-multi-RayTracer.ppm; } 2> ../pypy-multi-RayTracer.time && \
	tail -n 4 ../pypy-multi-RayTracer.time > ../pypy-multi-RayTracer.time.tmp && mv ../pypy-multi-RayTracer.time.tmp ../pypy-multi-RayTracer.time && \
	cd ..

cpp:
	cd cpp-RayTracer && \
	cmake -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_OPENMP=OFF && cmake --build build -j && \
	echo "Running C++ Ray Tracer..." && \
	{ time ./build/inOneWeekend > ../cpp-RayTracer.ppm; } 2> ../cpp-RayTracer.time && \
	tail -n 4 ../cpp-RayTracer.time > ../cpp-RayTracer.time.tmp && mv ../cpp-RayTracer.time.tmp ../cpp-RayTracer.time && \
	cd ..

cpp-multi:
	cd cpp-RayTracer && \
	cmake -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_OPENMP=ON && cmake --build build -j && \
	echo "Running C++ Ray Tracer..." && \
	{ time ./build/inOneWeekend > ../cpp-multi-RayTracer.ppm; } 2> ../cpp-multi-RayTracer.time && \
	tail -n 4 ../cpp-multi-RayTracer.time > ../cpp-multi-RayTracer.time.tmp && mv ../cpp-multi-RayTracer.time.tmp ../cpp-multi-RayTracer.time && \
	cd ..

go:
	cd go-RayTracer && \
	go build && \
	{ time ./ray-tracer > ../go-RayTracer.ppm; } 2> ../go-RayTracer.time && \
	tail -n 4 ../go-RayTracer.time > ../go-RayTracer.time.tmp && mv ../go-RayTracer.time.tmp ../go-RayTracer.time && \
	cd ..

go-multi:
	cd go-RayTracer && \
	go build -tags openmp && \
	{ time MULTITHREADING=1 ./ray-tracer > ../go-multi-RayTracer.ppm; } 2> ../go-multi-RayTracer.time && \
	tail -n 4 ../go-multi-RayTracer.time > ../go-multi-RayTracer.time.tmp && mv ../go-multi-RayTracer.time.tmp ../go-multi-RayTracer.time && \
	cd ..

rust:
	cd rust-RayTracer && \
	cargo build --release && \
	{ time ./target/release/ray-tracer > ../rust-RayTracer.ppm; } 2> ../rust-RayTracer.time && \
	tail -n 4 ../rust-RayTracer.time > ../rust-RayTracer.time.tmp && mv ../rust-RayTracer.time.tmp ../rust-RayTracer.time && \
	cd ..

all:
	@echo "Running all implementations..."
	@$(MAKE) cpp
	@$(MAKE) cpp-multi
	@$(MAKE) go
	@$(MAKE) go-multi
	@$(MAKE) rust
	@$(MAKE) pypy
	@$(MAKE) pypy-multi
	@$(MAKE) python
	@$(MAKE) python-multi

	@echo "All implementations completed."
	@echo "Generated images:"
	@ls -lh *.ppm
	@echo "You can view the images using an image viewer."

clean:
	@echo "Cleaning up..."
	@rm -f *.ppm 
	@rm -f *.time
	@echo "Cleaned up."