package main

// HittableList represents a collection of hittable objects
type HittableList struct {
	Objects []Hittable
}

// NewHittableList creates a new empty hittable list
func NewHittableList() *HittableList {
	return &HittableList{
		Objects: []Hittable{},
	}
}

// NewHittableListWithObject creates a new hittable list with one object
func NewHittableListWithObject(object Hittable) *HittableList {
	return &HittableList{
		Objects: []Hittable{object},
	}
}

// Clear removes all objects from the list
func (hl *HittableList) Clear() {
	hl.Objects = []Hittable{}
}

// Add appends an object to the list
func (hl *HittableList) Add(object Hittable) {
	hl.Objects = append(hl.Objects, object)
}

// Hit determines if a ray hits any object in the list and records the closest hit
func (hl *HittableList) Hit(r Ray, rayT Interval, rec *HitRecord) bool {
	tempRec := &HitRecord{}
	hitAnything := false
	closestSoFar := rayT.Max

	for _, object := range hl.Objects {
		if object.Hit(r, Interval{Min: rayT.Min, Max: closestSoFar}, tempRec) {
			hitAnything = true
			closestSoFar = tempRec.T
			*rec = *tempRec
		}
	}

	return hitAnything
}

// Ensure HittableList implements Hittable interface
var _ Hittable = (*HittableList)(nil)
