package main

import (
	"fmt"
	"io"
	"math"
	"os"
	"sync"
)

// Camera represents the view into the scene
type Camera struct {
	// Public configuration parameters
	AspectRatio     float64
	ImageWidth      int
	SamplesPerPixel int
	MaxDepth        int
	Vfov            float64
	LookFrom        Point3
	LookAt          Point3
	Vup             Vec3
	DefocusAngle    float64
	FocusDist       float64

	// Private fields
	imageHeight       int
	pixelSamplesScale float64
	center            Point3
	pixel00Loc        Point3
	pixelDeltaU       Vec3
	pixelDeltaV       Vec3
	u, v, w           Vec3
	defocusDiskU      Vec3
	defocusDiskV      Vec3
}

// NewCamera creates a camera with default settings
func NewCamera() *Camera {
	return &Camera{
		AspectRatio:     1.0,
		ImageWidth:      100,
		SamplesPerPixel: 10,
		MaxDepth:        10,
		Vfov:            90,
		LookFrom:        Point3{[3]float64{0, 0, 0}},
		LookAt:          Point3{[3]float64{0, 0, -1}},
		Vup:             Vec3{[3]float64{0, 1, 0}},
		DefocusAngle:    0,
		FocusDist:       10,
	}
}

// Initialize prepares the camera for rendering
func (c *Camera) Initialize() {
	c.imageHeight = int(float64(c.ImageWidth) / c.AspectRatio)
	if c.imageHeight < 1 {
		c.imageHeight = 1
	}

	c.pixelSamplesScale = 1.0 / float64(c.SamplesPerPixel)
	c.center = c.LookFrom

	// Determine viewport dimensions
	theta := DegreesToRadians(c.Vfov)
	h := math.Tan(theta / 2)
	viewportHeight := 2 * h * c.FocusDist
	viewportWidth := viewportHeight * (float64(c.ImageWidth) / float64(c.imageHeight))

	// Calculate the u,v,w unit basis vectors for the camera coordinate frame
	c.w = UnitVector(c.LookFrom.Sub(c.LookAt))
	c.u = UnitVector(Cross(c.Vup, c.w))
	c.v = Cross(c.w, c.u)

	// Calculate vectors across the horizontal and down the vertical viewport edges
	viewportU := c.u.MulScalar(viewportWidth)
	viewportV := c.v.MulScalar(-viewportHeight)

	// Calculate the horizontal and vertical delta vectors from pixel to pixel
	c.pixelDeltaU = viewportU.DivScalar(float64(c.ImageWidth))
	c.pixelDeltaV = viewportV.DivScalar(float64(c.imageHeight))

	// Calculate the location of the upper left pixel
	viewportUpperLeft := c.center.
		Sub(c.w.MulScalar(c.FocusDist)).
		Sub(viewportU.DivScalar(2)).
		Sub(viewportV.DivScalar(2))
	c.pixel00Loc = viewportUpperLeft.Add(
		c.pixelDeltaU.Add(c.pixelDeltaV).MulScalar(0.5))

	// Calculate the camera defocus disk basis vectors
	defocusRadius := c.FocusDist * math.Tan(DegreesToRadians(c.DefocusAngle/2))
	c.defocusDiskU = c.u.MulScalar(defocusRadius)
	c.defocusDiskV = c.v.MulScalar(defocusRadius)
}

// GetRay returns a ray for a given pixel coordinate
func (c *Camera) GetRay(i, j int) Ray {
	// Construct a camera ray originating from the defocus disk and directed at a randomly
	// sampled point around the pixel location i, j
	offset := c.sampleSquare()
	pixelSample := c.pixel00Loc.
		Add(c.pixelDeltaU.MulScalar(float64(i) + offset.X())).
		Add(c.pixelDeltaV.MulScalar(float64(j) + offset.Y()))

	rayOrigin := c.center
	if c.DefocusAngle > 0 {
		rayOrigin = c.defocusDiskSample()
	}
	rayDirection := pixelSample.Sub(rayOrigin)

	return Ray{Orig: rayOrigin, Dir: rayDirection}
}

// Render renders the scene with the given world
func (c *Camera) Render(world Hittable, out io.Writer, numThreads int) {
	c.Initialize()

	// Create image data
	img := NewImage(c.ImageWidth, c.imageHeight)

	if numThreads == 1 {
		for j := range c.imageHeight {
			fmt.Fprintf(os.Stdout, "\rScanlines remaining: %d ", c.imageHeight-j)
			for i := range c.ImageWidth {
				pixelColor := Color{[3]float64{0, 0, 0}}
				for range c.SamplesPerPixel {
					r := c.GetRay(i, j)
					pixelColor = pixelColor.Add(c.rayColor(r, c.MaxDepth, world))
				}
				img.SetPixel(i, j, pixelColor.MulScalar(c.pixelSamplesScale))
			}
		}
	} else {
		// Add a maximum of goroutines to the pool
		// This is a simple way to limit the number of concurrent goroutines
		// without using a channel or sync package

		// Create a wait group to synchronize goroutines
		var wg sync.WaitGroup
		waitChan := make(chan struct{}, numThreads)
		lines_remaining := c.imageHeight

		for pixel_idx := range c.imageHeight * c.ImageWidth {
			waitChan <- struct{}{}
			wg.Add(1)
			go func(pixel_idx int) {
				defer wg.Done()
				i := pixel_idx % c.ImageWidth
				j := pixel_idx / c.ImageWidth
				pixelColor := Color{[3]float64{0, 0, 0}}
				for range c.SamplesPerPixel {
					r := c.GetRay(i, j)
					pixelColor = pixelColor.Add(c.rayColor(r, c.MaxDepth, world))
				}
				img.SetPixel(i, j, pixelColor.MulScalar(c.pixelSamplesScale))
				if i == 0 {
					lines_remaining--
					fmt.Fprintf(os.Stdout, "\rScanlines remaining: %d ", lines_remaining)
				}
				<-waitChan
			}(pixel_idx)
		}
		wg.Wait()
	}
	fmt.Fprintf(os.Stdout, "\rScanlines remaining: 0 ")

	// Write the image to provided output
	img.WriteToStream(out)

	fmt.Fprintf(os.Stdout, "\rDone.                 \n")
}

// sampleSquare returns a random point in the [-0.5,0.5]x[-0.5,0.5] unit square
func (c *Camera) sampleSquare() Vec3 {
	return Vec3{[3]float64{
		RandomDouble() - 0.5,
		RandomDouble() - 0.5,
		0,
	}}
}

// defocusDiskSample returns a random point in the camera defocus disk
func (c *Camera) defocusDiskSample() Point3 {
	p := RandomInUnitDisk()
	return c.center.
		Add(c.defocusDiskU.MulScalar(p.E[0])).
		Add(c.defocusDiskV.MulScalar(p.E[1]))
}

// rayColor determines the color seen along a ray
func (c *Camera) rayColor(r Ray, depth int, world Hittable) Color {
	// If we've exceeded the ray bounce limit, no more light is gathered
	if depth <= 0 {
		return Color{[3]float64{0, 0, 0}}
	}

	rec := HitRecord{}
	if world.Hit(r, Interval{0.001, Infinity}, &rec) {
		reflect, attenuation, scattered := rec.Mat.Scatter(r, rec)
		if reflect {
			return attenuation.Mul(c.rayColor(scattered, depth-1, world))
		}
		return Color{[3]float64{0, 0, 0}}
	}

	unitDirection := UnitVector(r.Direction())
	a := 0.5 * (unitDirection.Y() + 1.0)
	white := Color{[3]float64{1.0, 1.0, 1.0}}
	blue := Color{[3]float64{0.5, 0.7, 1.0}}
	return white.MulScalar(1.0 - a).Add(blue.MulScalar(a))
}
