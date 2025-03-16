// Package rtweekend provides utility functions and constants for ray tracing.
// This is a port of the C++ code from "Ray Tracing in One Weekend" series.
package main

import (
	"math"
	"math/rand"
)

// Constants
const (
	Infinity = math.MaxFloat64
	Pi       = math.Pi
)

// DegreesToRadians converts degrees to radians
func DegreesToRadians(degrees float64) float64 {
	return degrees * Pi / 180.0
}

// RandomDouble returns a random float64 in [0,1)
func RandomDouble() float64 {
	// Returns a random real in [0,1)
	return rand.Float64()
}

// RandomDoubleRange returns a random float64 in [min,max)
func RandomDoubleRange(min, max float64) float64 {
	// Returns a random real in [min,max)
	return min + (max-min)*RandomDouble()
}
