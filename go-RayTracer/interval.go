package main

import (
	"math"
)

// Interval represents a range between two double values
type Interval struct {
	Min, Max float64
}

// Empty returns an empty interval
func Empty() Interval {
	return Interval{Min: math.Inf(1), Max: math.Inf(-1)}
}

// Universe returns an interval covering the entire real number line
func Universe() Interval {
	return Interval{Min: math.Inf(-1), Max: math.Inf(1)}
}

// NewInterval creates a new interval with the given min and max values
func NewInterval(min, max float64) Interval {
	return Interval{Min: min, Max: max}
}

// Size returns the size of the interval
func (i Interval) Size() float64 {
	return i.Max - i.Min
}

// Contains checks if the interval contains a given value
func (i Interval) Contains(x float64) bool {
	return i.Min <= x && x <= i.Max
}

// Surrounds checks if the interval strictly contains a given value
func (i Interval) Surrounds(x float64) bool {
	return i.Min < x && x < i.Max
}

// Clamp constrains a value to the interval
func (i Interval) Clamp(x float64) float64 {
	if x < i.Min {
		return i.Min
	}
	if x > i.Max {
		return i.Max
	}
	return x
}
