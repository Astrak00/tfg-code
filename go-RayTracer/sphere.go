package main

import (
	"math"
)

// Sphere represents a sphere in 3D space.
type Sphere struct {
	Center Vec3
	Radius float64
	Mat    Material
}

// NewSphere creates a new sphere with the given center, radius, and material.
func NewSphere(center Vec3, radius float64, mat Material) *Sphere {
	return &Sphere{
		Center: center,
		Radius: math.Max(0, radius),
		Mat:    mat,
	}
}

// Hit determines if a ray hits the sphere and records hit information.
func (s *Sphere) Hit(r Ray, rayT Interval, rec *HitRecord) bool {
	oc := s.Center.Sub(r.Origin())
	a := r.Direction().LengthSquared()
	h := Dot(r.Direction(), oc)
	c := oc.LengthSquared() - s.Radius*s.Radius

	discriminant := h*h - a*c
	if discriminant < 0 {
		return false
	}

	sqrtd := math.Sqrt(discriminant)

	// Find the nearest root that lies in the acceptable range
	root := (h - sqrtd) / a
	if !rayT.Surrounds(root) {
		root = (h + sqrtd) / a
		if !rayT.Surrounds(root) {
			return false
		}
	}

	rec.T = root
	rec.P = r.At(rec.T)
	outwardNormal := rec.P.Sub(s.Center).MulScalar(1 / s.Radius)
	rec.SetFaceNormal(r, outwardNormal)
	rec.Mat = s.Mat

	return true
}
