"""
Ray module that includes the Ray class, defined by an origin and a direction
"""
from vec3 import Vec3, Point3

class Ray():
    """A ray is defined by an origin and a direction"""
    def __init__(self, origin: Point3, direction: Vec3):
        self.origin = origin
        self.direction = direction

    def at(self, t: float) -> Point3:
        """Returns the point at t units along the ray"""
        return self.origin + t * self.direction
