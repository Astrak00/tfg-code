"""
Module that contains a class that defines a sphere in 3D space.
"""
from math import sqrt

from ray import Ray
from interval import Interval
from hittable import Hittable, HitRecord
from vec3 import Point3
from material import Material

class Sphere(Hittable):
    """A sphere in 3D space."""
    def __init__(self, center: Point3, radius: float, material: Material):
        self.center: Point3 = center
        self.radius = max(0, radius)
        self.material = material

    def hit(self, r: Ray, ray_t: Interval, rec: HitRecord):
        oc = self.center - r.origin
        a = r.direction.length_squared()
        half_b = oc.dot(r.direction)
        c = oc.length_squared() - self.radius*self.radius

        discriminant = half_b*half_b - a*c
        if discriminant < 0:
            return False

        sqrtd = sqrt(discriminant)

        root = (half_b - sqrtd) / a
        if not ray_t.surrounds(root):
            root = (half_b + sqrtd) / a
            if not ray_t.surrounds(root):
                return False

        rec.t = root
        rec.p = r.at(rec.t)
        outward_normal = (rec.p - self.center) / self.radius

        rec.set_face_normal(r, outward_normal)
        rec.material = self.material

        return True
