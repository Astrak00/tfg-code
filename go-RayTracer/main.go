package main

import (
	"bufio"
	"flag"
	"fmt"
	"math/rand"
	"os"
	"runtime"
	"strconv"
	"strings"
)

func createWorldFromFile(filepath string) (HittableList, error) {
	world := HittableList{}

	// Add ground Sphere
	groundMaterial := &Lambertian{Color{[3]float64{0.5, 0.5, 0.5}}}
	world.Add(NewSphere(Point3{[3]float64{0, -1000, 0}}, 1000, groundMaterial))

	// Open and read the file
	file, err := os.Open(filepath)
	if err != nil {
		return world, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		// Skip empty lines and comments
		if line == "" || strings.HasPrefix(strings.TrimSpace(line), "#") {
			continue
		}

		parts := strings.Fields(line)
		if len(parts) < 5 {
			continue // Need at least x, y, z, radius, material_type
		}

		// Parse coordinates and radius
		x, err1 := strconv.ParseFloat(parts[0], 64)
		y, err2 := strconv.ParseFloat(parts[1], 64)
		z, err3 := strconv.ParseFloat(parts[2], 64)
		radius, err4 := strconv.ParseFloat(parts[3], 64)
		if err1 != nil || err2 != nil || err3 != nil || err4 != nil {
			continue // Skip lines with invalid numbers
		}

		center := Point3{[3]float64{x, y, z}}
		materialType := parts[4]

		// Parse material based on type
		switch materialType {
		case "lambertian":
			if len(parts) >= 8 {
				r, err1 := strconv.ParseFloat(parts[5], 64)
				g, err2 := strconv.ParseFloat(parts[6], 64)
				b, err3 := strconv.ParseFloat(parts[7], 64)
				if err1 != nil || err2 != nil || err3 != nil {
					continue
				}
				material := &Lambertian{Color{[3]float64{r, g, b}}}
				world.Add(NewSphere(center, radius, material))
			}
		case "metal":
			if len(parts) >= 9 {
				r, err1 := strconv.ParseFloat(parts[5], 64)
				g, err2 := strconv.ParseFloat(parts[6], 64)
				b, err3 := strconv.ParseFloat(parts[7], 64)
				fuzz, err4 := strconv.ParseFloat(parts[8], 64)
				if err1 != nil || err2 != nil || err3 != nil || err4 != nil {
					continue
				}
				material := &Metal{Albedo: Color{[3]float64{r, g, b}}, Fuzz: fuzz}
				world.Add(NewSphere(center, radius, material))
			}
		case "dielectric":
			if len(parts) >= 6 {
				index, err := strconv.ParseFloat(parts[5], 64)
				if err != nil {
					continue
				}
				material := &Dielectric{index}
				world.Add(NewSphere(center, radius, material))
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return world, err
	}

	fmt.Errorf("Loaded world from %s\n", filepath)
	return world, nil
}

func randomScene() HittableList {
	world := HittableList{}

	// Add ground Sphere
	groundMaterial := &Lambertian{Color{[3]float64{0.5, 0.5, 0.5}}}
	world.Add(NewSphere(Point3{[3]float64{0, -1000, 0}}, 1000, groundMaterial))

	// Save the random scene to a file
	file, err := os.Create("sphere_data.txt")
	if err == nil {
		defer file.Close()
		writer := bufio.NewWriter(file)

		// Create random Spheres
		for a := -11; a < 11; a++ {
			for b := -11; b < 11; b++ {
				chooseMat := rand.Float64()
				center := Point3{[3]float64{float64(a) + 0.9*rand.Float64(), 0.2, float64(b) + 0.9*rand.Float64()}}

				if center.Sub(Point3{[3]float64{4, 0.2, 0}}).Length() > 0.9 {
					var sphereMaterial Material

					if chooseMat < 0.8 {
						// Diffuse material
						albedo := RandomVec3().Mul(RandomVec3())
						sphereMaterial = &Lambertian{albedo}
						world.Add(NewSphere(center, 0.2, sphereMaterial))

						// Write to file
						fmt.Fprintf(writer, "%f %f %f %f lambertian %f %f %f\n",
							center.E[0], center.E[1], center.E[2], 0.2,
							albedo.E[0], albedo.E[1], albedo.E[2])
					} else if chooseMat < 0.95 {
						// Metal material
						var albedo Color = RandomVec3Range(0.1, 1)
						fuzz := rand.Float64() * 0.5
						sphereMaterial = &Metal{albedo, fuzz}
						world.Add(NewSphere(center, 0.2, sphereMaterial))

						// Write to file
						fmt.Fprintf(writer, "%f %f %f %f metal %f %f %f %f\n",
							center.E[0], center.E[1], center.E[2], 0.2,
							albedo.E[0], albedo.E[1], albedo.E[2], fuzz)
					} else {
						// Glass material
						sphereMaterial = &Dielectric{1.5}
						world.Add(NewSphere(center, 0.2, sphereMaterial))

						// Write to file
						fmt.Fprintf(writer, "%f %f %f %f dielectric %f\n",
							center.E[0], center.E[1], center.E[2], 0.2, 1.5)
					}
				}
			}
		}

		// Add three large Spheres
		material1 := &Dielectric{1.5}
		world.Add(NewSphere(Point3{[3]float64{0, 1, 0}}, 1.0, material1))
		fmt.Fprintf(writer, "%f %f %f %f dielectric %f\n", 0.0, 1.0, 0.0, 1.0, 1.5)

		material2 := &Lambertian{Color{[3]float64{0.4, 0.2, 0.1}}}
		world.Add(NewSphere(Point3{[3]float64{-4, 1, 0}}, 1.0, material2))
		fmt.Fprintf(writer, "%f %f %f %f lambertian %f %f %f\n", -4.0, 1.0, 0.0, 1.0, 0.4, 0.2, 0.1)

		material3 := &Metal{Albedo: Color{[3]float64{0.7, 0.6, 0.5}}, Fuzz: 0.0}
		world.Add(NewSphere(Point3{[3]float64{4, 1, 0}}, 1.0, material3))
		fmt.Fprintf(writer, "%f %f %f %f metal %f %f %f %f\n", 4.0, 1.0, 0.0, 1.0, 0.7, 0.6, 0.5, 0.0)

		writer.Flush()
	}

	return world
}

func main() {
	// Parse command-line arguments
	filepath := flag.String("path", "sphere_data.txt", "Path to the sphere data file")
	flag.Parse()

	numThreads := 1

	numThreadsEnv := os.Getenv("MULTITHREADING")
	if numThreadsEnv == "" {
		numThreads = runtime.NumCPU()
	}

	// Initialize world - either from file or randomly generated
	var world HittableList

	if _, err := os.Stat(*filepath); err == nil {
		// File exists, try to read it
		world, err = createWorldFromFile(*filepath)
		if err != nil {
			fmt.Printf("Error reading from %s: %v\n", *filepath, err)
			fmt.Println("Generating random scene instead.")
			world = randomScene()
		}
	} else {
		fmt.Printf("File %s not found. Generating random scene instead.\n", *filepath)
		world = randomScene()
	}

	// Setup and render camera
	cam := Camera{
		AspectRatio:     16.0 / 9.0,
		ImageWidth:      800,
		SamplesPerPixel: 50,
		MaxDepth:        50,
		Vfov:            20,

		LookFrom: Point3{[3]float64{13, 2, 3}},
		LookAt:   Point3{[3]float64{0, 0, 0}},
		Vup:      Vec3{[3]float64{0, 1, 0}},

		DefocusAngle: 0.6,
		FocusDist:    10.0,
	}

	cam.Render(&world, numThreads)
}
