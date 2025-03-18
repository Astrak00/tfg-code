package main

import (
	"math"
	"math/rand"
)

// Vec3 represents a 3D vector
type Vec3 struct {
	E [3]float64
}

// NewVec3 creates a new Vec3 with the given components
func NewVec3(e0, e1, e2 float64) Vec3 {
	return Vec3{E: [3]float64{e0, e1, e2}}
}

// X returns the x component
func (v Vec3) X() float64 { return v.E[0] }

// Y returns the y component
func (v Vec3) Y() float64 { return v.E[1] }

// Z returns the z component
func (v Vec3) Z() float64 { return v.E[2] }

// Neg returns a vector with all components negated
func (v Vec3) Neg() Vec3 {
	return NewVec3(-v.E[0], -v.E[1], -v.E[2])
}

// At returns the component at index i
func (v Vec3) At(i int) float64 {
	return v.E[i]
}

// Add adds another vector to this one and returns the result
func (v Vec3) Add(other Vec3) Vec3 {
	return NewVec3(v.E[0]+other.E[0], v.E[1]+other.E[1], v.E[2]+other.E[2])
}

// Sub subtracts another vector from this one and returns the result
func (v Vec3) Sub(other Vec3) Vec3 {
	return NewVec3(v.E[0]-other.E[0], v.E[1]-other.E[1], v.E[2]-other.E[2])
}

// Mul multiplies two vectors component-wise
func (v Vec3) Mul(other Vec3) Vec3 {
	return NewVec3(v.E[0]*other.E[0], v.E[1]*other.E[1], v.E[2]*other.E[2])
}

// MulScalar multiplies the vector by a scalar
func (v Vec3) MulScalar(t float64) Vec3 {
	return NewVec3(t*v.E[0], t*v.E[1], t*v.E[2])
}

// DivScalar divides the vector by a scalar
func (v Vec3) DivScalar(t float64) Vec3 {
	return v.MulScalar(1 / t)
}

// LengthSquared returns the squared length of the vector
func (v Vec3) LengthSquared() float64 {
	return v.E[0]*v.E[0] + v.E[1]*v.E[1] + v.E[2]*v.E[2]
}

// Length returns the length of the vector
func (v Vec3) Length() float64 {
	return math.Sqrt(v.LengthSquared())
}

// NearZero returns true if the vector is close to zero in all dimensions
func (v Vec3) NearZero() bool {
	s := 1e-8
	return (math.Abs(v.E[0]) < s) && (math.Abs(v.E[1]) < s) && (math.Abs(v.E[2]) < s)
}

// Random returns a random vector with components in [0,1)
func RandomVec3() Vec3 {
	return NewVec3(rand.Float64(), rand.Float64(), rand.Float64())
}

// RandomRange returns a random vector with components in [min,max)
func RandomVec3Range(min, max float64) Vec3 {
	return NewVec3(
		min+rand.Float64()*(max-min),
		min+rand.Float64()*(max-min),
		min+rand.Float64()*(max-min),
	)
}

// Point3 is just an alias for Vec3, but useful for geometric clarity
type Point3 = Vec3

// Dot returns the dot product of two vectors
func Dot(u, v Vec3) float64 {
	return u.E[0]*v.E[0] + u.E[1]*v.E[1] + u.E[2]*v.E[2]
}

// Cross returns the cross product of two vectors
func Cross(u, v Vec3) Vec3 {
	return NewVec3(
		u.E[1]*v.E[2]-u.E[2]*v.E[1],
		u.E[2]*v.E[0]-u.E[0]*v.E[2],
		u.E[0]*v.E[1]-u.E[1]*v.E[0],
	)
}

// UnitVector returns the unit vector in the direction of v
func UnitVector(v Vec3) Vec3 {
	return v.DivScalar(v.Length())
}

// RandomInUnitDisk returns a random vector in the unit disk
func RandomInUnitDisk() Vec3 {
	for {
		p := NewVec3(2*rand.Float64()-1, 2*rand.Float64()-1, 0)
		if p.LengthSquared() < 1 {
			return p
		}
	}
}

// RandomUnitVector returns a random unit vector
func RandomUnitVector() Vec3 {
	for {
		p := RandomVec3Range(-1, 1)
		lensq := p.LengthSquared()
		if 1e-160 < lensq && lensq <= 1.0 {
			return p.DivScalar(math.Sqrt(lensq))
		}
	}
}

// RandomOnHemisphere returns a random vector on the hemisphere oriented by the normal
func RandomOnHemisphere(normal Vec3) Vec3 {
	onUnitSphere := RandomUnitVector()
	if Dot(onUnitSphere, normal) > 0.0 {
		return onUnitSphere
	}
	return onUnitSphere.Neg()
}

// Reflect reflects a vector according to a normal
func Reflect(v, n Vec3) Vec3 {
	return v.Sub(n.MulScalar(2 * Dot(v, n)))
}

// Refract refracts a vector according to a normal and ratio of refraction indices
func Refract(uv, n Vec3, etaiOverEtat float64) Vec3 {
	cosTheta := math.Min(Dot(uv.Neg(), n), 1.0)
	rOutPerp := uv.Add(n.MulScalar(cosTheta)).MulScalar(etaiOverEtat)
	rOutParallel := n.MulScalar(-math.Sqrt(math.Abs(1.0 - rOutPerp.LengthSquared())))
	return rOutPerp.Add(rOutParallel)
}
