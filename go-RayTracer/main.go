package main

import (
	"math/rand"
	"os"
	"strconv"
)

func main() {
	numThreads := 1

	numThreadsEnv := os.Getenv("OMP_NUM_THREADS")
	if numThreadsEnv != "" {
		if numThreadsEnvInt, err := strconv.Atoi(numThreadsEnv); err == nil {
			numThreads = numThreadsEnvInt
		}
	}

	// Initialize world with a large ground Sphere and random smaller Spheres
	world := HittableList{}

	// Add ground Sphere
	groundMaterial := &Lambertian{Color{[3]float64{0.5, 0.5, 0.5}}}
	world.Add(&Sphere{Point3{[3]float64{0, -1000, 0}}, 1000, groundMaterial})

	// Create random Spheres
	for a := -11; a < 11; a++ {
		for b := -11; b < 11; b++ {
			chooseMat := rand.Float64()
			center := Point3{[3]float64{float64(a) + 0.9*rand.Float64(), 0.2, float64(b) + 0.9*rand.Float64()}}

			if center.Sub(Point3{[3]float64{4, 0.2, 0}}).Length() > 0.9 {
				var SphereMaterial Material

				if chooseMat < 0.8 {
					// Diffuse material
					albedo := RandomVec3().Mul(RandomVec3())
					SphereMaterial = &Lambertian{albedo}
				} else if chooseMat < 0.95 {
					// Metal material
					var albedo Color = RandomVec3Range(0.1, 1)
					fuzz := rand.Float64() * 0.5
					SphereMaterial = &Metal{albedo, fuzz}
				} else {
					// Glass material
					SphereMaterial = &Dielectric{1.5}
				}
				world.Add(&Sphere{center, 0.2, SphereMaterial})
			}
		}
	}

	// Add three large Spheres
	material1 := &Dielectric{1.5}
	world.Add(&Sphere{Point3{[3]float64{0, 1, 0}}, 1.0, material1})

	material2 := &Lambertian{Color{[3]float64{0.4, 0.2, 0.1}}}
	world.Add(&Sphere{Point3{[3]float64{-4, 1, 0}}, 1.0, material2})

	material3 := &Metal{Albedo: Color{[3]float64{0.7, 0.6, 0.5}}, Fuzz: 0.0}
	world.Add(&Sphere{Point3{[3]float64{4, 1, 0}}, 1.0, material3})

	// Setup and render camera
	cam := Camera{
		AspectRatio:     16.0 / 9.0,
		ImageWidth:      400,
		SamplesPerPixel: 20,
		MaxDepth:        20,

		Vfov:            20,
		LookFrom:        Point3{[3]float64{13, 2, 3}},
		LookAt:          Point3{[3]float64{0, 0, 0}},
		Vup:             Vec3{[3]float64{0, 1, 0}},
		
		DefocusAngle:    0.6,
		FocusDist:       10.0,
	}

	cam.Render(&world, numThreads)
}
