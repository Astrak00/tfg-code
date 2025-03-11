"""
This module contains classes for hittable objects.
"""
from interval import Interval
from ray import Ray
from vec3 import Point3, Vec3


class Material:
    """
    Virtual class for materials.
    """

class HitRecord:
    """
    A class to represent a hit record.
    """
    def __init__(self):
        self.p: Point3
        self.normal: Vec3
        self.t: float
        self.front_face: bool
        self.material: Material

    def set_face_normal(self, r: Ray, outward_normal: Vec3):
        """
        Set the face normal.
        """
        if not isinstance(outward_normal, Vec3):
            raise TypeError("outward_normal must be a Vec3.")
        direction: Vec3 = r.direction
        self.front_face = direction.dot(outward_normal) < 0
        self.normal = outward_normal if self.front_face else -outward_normal


class Hittable:
    """
    A class to represent a hittable object.
    """
    def hit(self, r: Ray, ray_t: Interval, rec: HitRecord) -> bool:
        """
        Virtual method to check if a ray hits the object.
        """
        raise NotImplementedError("Subclasses should implement this method.")
