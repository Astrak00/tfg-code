package main

// Ray represents a ray with an origin and direction vector.
type Ray struct {
	Orig Point3
	Dir  Vec3
}

// NewRay creates a new ray with the given origin and direction.
func NewRay(origin Point3, direction Vec3) Ray {
	return Ray{
		Orig: origin,
		Dir:  direction,
	}
}

// Origin returns the ray's origin point.
func (r Ray) Origin() Point3 {
	return r.Orig
}

// Direction returns the ray's direction vector.
func (r Ray) Direction() Vec3 {
	return r.Dir
}

// At returns the position along the ray at the given parameter t.
func (r Ray) At(t float64) Point3 {
	return r.Orig.Add(r.Dir.MulScalar(t))
}
