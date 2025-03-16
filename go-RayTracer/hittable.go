package main

// Material is an interface that represents a material type
type Material interface {
	Scatter(rIn Ray, rec HitRecord) (bool, Color, Ray)
}

// HitRecord stores information about a ray-object intersection
type HitRecord struct {
	P         Point3
	Normal    Vec3
	Mat       Material
	T         float64
	FrontFace bool
}

// SetFaceNormal sets the hit record normal vector based on the ray direction and the outward normal
func (rec *HitRecord) SetFaceNormal(r Ray, outwardNormal Vec3) {
	// Sets the hit record normal vector.
	// NOTE: the parameter `outwardNormal` is assumed to have unit length.

	rec.FrontFace = Dot(r.Direction(), outwardNormal) < 0
	if rec.FrontFace {
		rec.Normal = outwardNormal
	} else {
		rec.Normal = outwardNormal.Neg()
	}
}

// Hittable is an interface for objects that can be hit by a ray
type Hittable interface {
	Hit(r Ray, rayT Interval, rec *HitRecord) bool
}
