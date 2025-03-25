import math
import random
from vector import Vector
from ray import Ray

class Camera:
    def __init__(self, lookfrom, lookat, vup, vfov, aspect_ratio, aperture, focus_dist):
        theta = math.radians(vfov)
        h = math.tan(theta/2)
        viewport_height = 2.0 * h
        viewport_width = aspect_ratio * viewport_height
        
        self.w = (lookfrom - lookat).normalize()
        self.u = vup.cross(self.w).normalize()
        self.v = self.w.cross(self.u)
        
        self.origin = lookfrom
        self.horizontal = focus_dist * viewport_width * self.u
        self.vertical = focus_dist * viewport_height * self.v
        self.lower_left_corner = (self.origin - self.horizontal/2 - 
                                  self.vertical/2 - focus_dist * self.w)
        
        self.lens_radius = aperture / 2
    
    def get_ray(self, s, t):
        rd = self.lens_radius * random_in_unit_disk()
        offset = self.u * rd.x + self.v * rd.y
        
        return Ray(
            self.origin + offset,
            self.lower_left_corner + s*self.horizontal + t*self.vertical - self.origin - offset
        )

def random_in_unit_disk():
    while True:
        p = Vector(random.uniform(-1, 1), random.uniform(-1, 1), 0)
        if p.dot(p) < 1:
            return p
