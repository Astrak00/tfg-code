package main

import (
	"fmt"
	"io"
	"math"
)

// Color is equivalent to Vec3 for representing colors
type Color = Vec3

// LinearToGamma converts a linear component to gamma space (gamma 2)
func LinearToGamma(linearComponent float64) float64 {
	if linearComponent > 0 {
		return math.Sqrt(linearComponent)
	}
	return 0
}

// Clamp ensures a value is within the specified interval
func Clamp(x, min, max float64) float64 {
	if x < min {
		return min
	}
	if x > max {
		return max
	}
	return x
}

// WriteColor outputs the color in the PPM format
func WriteColor(out io.Writer, pixelColor Color) {

	r := pixelColor.X()
	g := pixelColor.Y()
	b := pixelColor.Z()

	// Apply linear to gamma transform for gamma 2
	r = LinearToGamma(r)
	g = LinearToGamma(g)
	b = LinearToGamma(b)

	// Translate [0,1] to byte range [0,255]
	intensity := struct{ min, max float64 }{0.000, 0.999}
	rByte := int(256 * Clamp(r, intensity.min, intensity.max))
	gByte := int(256 * Clamp(g, intensity.min, intensity.max))
	bByte := int(256 * Clamp(b, intensity.min, intensity.max))

	fmt.Fprintf(out, "%d %d %d\n", rByte, gByte, bByte)
}
