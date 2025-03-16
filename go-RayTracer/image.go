package main

import (
	"fmt"
	"io"
)

// Color represents an RGB color

// Image represents a simple image with width, height, and pixel data
type Image struct {
	width, height int
	pixels        []Color
}

// NewImage creates a new image with the specified dimensions
func NewImage(width, height int) *Image {
	return &Image{
		width:  width,
		height: height,
		pixels: make([]Color, width*height),
	}
}

// Pixel returns a reference to the pixel at position (x, y)
func (img *Image) Pixel(x, y int) *Color {
	return &img.pixels[y*img.width+x]
}

func (img *Image) SetPixel(x, y int, color Color) {
	img.pixels[y*img.width+x] = color
}

// WriteToStream outputs the image in PPM format to the provided writer
func (img *Image) WriteToStream(out io.Writer) {
	// Output the PPM header
	fmt.Fprintf(out, "P3\n%d %d\n255\n", img.width, img.height)

	// Output all pixels
	for j := 0; j < img.height; j++ {
		for i := 0; i < img.width; i++ {
			WriteColor(out, img.pixels[j*img.width+i])
		}
	}
}
