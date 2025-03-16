package main

import (
	"math"
	"math/rand"
)

// Lambertian is a diffuse material
type Lambertian struct {
	Albedo Color
}

// Scatter calculates how light scatters from a Lambertian surface
func (l *Lambertian) Scatter(rIn Ray, rec HitRecord) (bool, Color, Ray) {
	scatterDirection := rec.Normal.Add(RandomUnitVector())

	// Catch degenerate scatter direction
	if scatterDirection.NearZero() {
		scatterDirection = rec.Normal
	}

	scattered := Ray{rec.P, scatterDirection}
	attenuation := l.Albedo
	return true, attenuation, scattered
}

// Metal is a reflective material
type Metal struct {
	Albedo Color
	Fuzz   float64 // 0 for perfect mirror, higher for fuzzier reflection
}

// Scatter calculates how light scatters from a metal surface
func (m *Metal) Scatter(rIn Ray, rec HitRecord) (bool, Color, Ray) {
	reflected := Reflect(UnitVector(rIn.Direction()), rec.Normal)

	// Add fuzziness to the reflection
	fuzz := math.Min(m.Fuzz, 1.0)
	fuzzVector := RandomUnitVector().MulScalar(fuzz)
	reflected = reflected.Add(fuzzVector)

	scattered := Ray{rec.P, reflected}
	attenuation := m.Albedo

	// Only scatter if the ray reflects outward
	return Dot(scattered.Direction(), rec.Normal) > 0, attenuation, scattered
}

// Dielectric is a transparent material like glass or water
type Dielectric struct {
	RefractionIndex float64
}

// Scatter calculates how light scatters through a dielectric surface
func (d *Dielectric) Scatter(rIn Ray, rec HitRecord) (bool, Color, Ray) {
	attenuation := Color{[3]float64{1.0, 1.0, 1.0}} // Glass doesn't absorb any light
	var refractionRatio float64
	if rec.FrontFace {
		refractionRatio = 1.0 / d.RefractionIndex
	} else {
		refractionRatio = d.RefractionIndex
	}

	unitDirection := UnitVector(rIn.Direction())
	cosTheta := math.Min(Dot(unitDirection.Neg(), rec.Normal), 1.0)
	sinTheta := math.Sqrt(1.0 - cosTheta*cosTheta)

	// Determine if we must reflect
	cannotRefract := refractionRatio*sinTheta > 1.0
	var direction Vec3

	if cannotRefract || d.reflectance(cosTheta, refractionRatio) > rand.Float64() {
		direction = Reflect(unitDirection, rec.Normal)
	} else {
		direction = Refract(unitDirection, rec.Normal, refractionRatio)
	}

	scattered := Ray{rec.P, direction}
	return true, attenuation, scattered
}

// reflectance calculates the Schlick approximation
func (d *Dielectric) reflectance(cosine, refIdx float64) float64 {
	// Use Schlick's approximation for reflectance
	r0 := (1.0 - refIdx) / (1.0 + refIdx)
	r0 = r0 * r0
	return r0 + (1.0-r0)*math.Pow((1.0-cosine), 5)
}
