package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"math/rand"
	"os"
	"runtime"
	"strconv"
	"strings"
)

func checkCameraParameters(cam *Camera, line string) {
	parts := strings.Fields(line)
	switch parts[1] {
	case "ratio":
		firstComponent, err := strconv.ParseFloat(parts[2], 64)
		secondComponent, err2 := strconv.ParseFloat(parts[3], 64)
		if err == nil && err2 == nil {
			cam.AspectRatio = firstComponent / secondComponent
		} else {
			fmt.Println("Invalid aspect ratio values.")
		}
	case "width":
		width, err := strconv.Atoi(parts[2])
		if err == nil {
			cam.ImageWidth = width
		} else {
			fmt.Println("Invalid image width value.")
		}
	case "samplesPerPixel":
		samples, err := strconv.Atoi(parts[2])
		if err == nil {
			cam.SamplesPerPixel = samples
		} else {
			fmt.Println("Invalid samples per pixel value.")
		}
	case "maxDepth":
		maxDepth, err := strconv.Atoi(parts[2])
		if err == nil {
			cam.MaxDepth = maxDepth
		} else {
			fmt.Println("Invalid max depth value.")
		}
	case "vfov":
		vfov, err := strconv.ParseFloat(parts[2], 64)
		if err == nil {
			cam.Vfov = vfov
		} else {
			fmt.Println("Invalid vertical field of view value.")
		}
	case "lookFrom":
		if len(parts) >= 5 {
			x, err1 := strconv.ParseFloat(parts[2], 64)
			y, err2 := strconv.ParseFloat(parts[3], 64)
			z, err3 := strconv.ParseFloat(parts[4], 64)
			if err1 == nil && err2 == nil && err3 == nil {
				cam.LookFrom = Point3{[3]float64{x, y, z}}
			} else {
				fmt.Println("Invalid lookFrom values.")
			}
		}
	case "lookAt":
		if len(parts) >= 5 {
			x, err1 := strconv.ParseFloat(parts[2], 64)
			y, err2 := strconv.ParseFloat(parts[3], 64)
			z, err3 := strconv.ParseFloat(parts[4], 64)
			if err1 == nil && err2 == nil && err3 == nil {
				cam.LookAt = Point3{[3]float64{x, y, z}}
			} else {
				fmt.Println("Invalid lookAt values.")
			}
		}
	case "vup":
		if len(parts) >= 5 {
			x, err1 := strconv.ParseFloat(parts[2], 64)
			y, err2 := strconv.ParseFloat(parts[3], 64)
			z, err3 := strconv.ParseFloat(parts[4], 64)
			if err1 == nil && err2 == nil && err3 == nil {
				cam.Vup = Vec3{[3]float64{x, y, z}}
			} else {
				fmt.Println("Invalid vup values.")
			}
		}
	case "defocusAngle":
		angle, err := strconv.ParseFloat(parts[2], 64)
		if err == nil {
			cam.DefocusAngle = angle
		} else {
			fmt.Println("Invalid defocus angle value.")
		}
	case "focusDist":
		focusDist, err := strconv.ParseFloat(parts[2], 64)
		if err == nil {
			cam.FocusDist = focusDist
		} else {
			fmt.Println("Invalid focus distance value.")
		}
	default:
		fmt.Println("Unknown camera parameter:", parts[1])
	}

}

func createWorldFromFile(filepath string) (HittableList, Camera, error) {
	world := HittableList{}
	cam := Camera{}

	// Add ground Sphere
	groundMaterial := &Lambertian{Color{[3]float64{0.5, 0.5, 0.5}}}
	world.Add(NewSphere(Point3{[3]float64{0, -1000, 0}}, 1000, groundMaterial))

	// Open and read the file
	file, err := os.Open(filepath)
	if err != nil {
		return world, cam, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		// Skip empty lines and comments
		if line == "" || strings.HasPrefix(strings.TrimSpace(line), "#") {
			continue
		}
		// Check for camera parameters

		if strings.HasPrefix(line, "c") {
			checkCameraParameters(&cam, line)
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
		return world, cam, err
	}

	fmt.Printf("Loaded world from %s\n", filepath)
	return world, cam, nil
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
	outputPath := flag.String("output", "", "Output PPM file path (default: stdout)")
	numThreadsArg := flag.Int("cores", 0, "Number of CPU cores to use (default: all available cores)")
	flag.Parse()

	fmt.Println("Cores:", *numThreadsArg)

	numThreads := 1
	if *numThreadsArg == 0 {
		numThreads = runtime.NumCPU()
	} else {
		numThreads = *numThreadsArg
	}

	// Initialize world - either from file or randomly generated
	var world HittableList
	var cam Camera

	if _, err := os.Stat(*filepath); err == nil {
		// File exists, try to read it
		world, cam, err = createWorldFromFile(*filepath)
		if err != nil {
			fmt.Printf("Error reading from %s: %v\n", *filepath, err)
			fmt.Println("Generating random scene instead.")
			world = randomScene()
		}
	} else {
		fmt.Printf("File %s not found. Generating random scene instead.\n", *filepath)
		world = randomScene()
	}

	// Determine the output destination
	var output io.Writer = os.Stdout
	var outputFile *os.File
	if *outputPath != "" {
		var err error
		outputFile, err = os.Create(*outputPath)
		if err != nil {
			fmt.Printf("Error: Could not create output file %s: %v\n", *outputPath, err)
			os.Exit(1)
		}
		defer outputFile.Close()
		output = outputFile
	}

	fmt.Println("I'm using ", numThreads, "threads for rendering.")
	cam.Render(&world, output, numThreads)
}
