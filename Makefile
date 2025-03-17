python:
	cd python-RayTracer && \
	{ time python3 main.py > ../py-RayTracer.ppm; } 2> ../py-RayTracer.time && \
	tail -n 4 ../py-RayTracer.time > ../py-RayTracer.time.tmp && mv ../py-RayTracer.time.tmp ../py-RayTracer.time && \
	cd ..

pypy:
	cd python-RayTracer && \
	{ time pypy main.py > ../pypy-RayTracer.ppm; } 2> ../pypy-RayTracer.time && \
	tail -n 4 ../pypy-RayTracer.time > ../pypy-RayTracer.time.tmp && mv ../pypy-RayTracer.time.tmp ../pypy-RayTracer.time && \
	cd ..

cpp:
	cd cpp-RayTracer && \
	cmake -B build && cmake --build build && \
	{ time ./build/inOneWeekend > ../cpp-RayTracer.ppm; } 2> ../cpp-RayTracer.time && \
	tail -n 4 ../cpp-RayTracer.time > ../cpp-RayTracer.time.tmp && mv ../cpp-RayTracer.time.tmp ../cpp-RayTracer.time && \
	cd ..

go:
	cd go-RayTracer && \
	go build && \
	{ time ./ray-tracer > ../go-RayTracer.ppm; } 2> ../go-RayTracer.time && \
	tail -n 4 ../go-RayTracer.time > ../go-RayTracer.time.tmp && mv ../go-RayTracer.time.tmp ../go-RayTracer.time && \
	cd ..

go-100:
	cd go-RayTracer && \
	go build && \
	{ time OMP_NUM_THREADS=10 ./ray-tracer > ../go-RayTracer-10.ppm; } 2> ../go-RayTracer-10.time && \
	tail -n 4 ../go-RayTracer-10.time > ../go-RayTracer-10.time.tmp && mv ../go-RayTracer-10.time.tmp ../go-RayTracer-10.time && \
	cd ..

all:
	@echo "Running all implementations..."
	@$(MAKE) cpp
	@$(MAKE) go
	@$(MAKE) pypy
	@$(MAKE) go-10
	@$(MAKE) python

	@echo "All implementations completed."
	@echo "Generated images:"
	@ls -lh *.ppm
	@echo "You can view the images using an image viewer."


clean:
	@echo "Cleaning up..."
	@rm -f *.ppm 
	@rm -f *.time
	@echo "Cleaned up."