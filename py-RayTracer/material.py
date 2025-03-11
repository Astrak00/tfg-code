"""
This module contains classes for materials
"""

from ray import Ray
from hittable import HitRecord
from color import Color
from vec3 import random_unit_vector

class Material():
    """
    Abstract class for materials
    """
    def __init__(self):
        pass

    def scatter(self, r_in: Ray, rec: HitRecord, attenuation: Color, scattered: Ray) -> bool:
        """
        Virtual method to scatter light
        """
        raise NotImplementedError("scatter() method not implemented in Material class")

class Lambertian(Material):
    """
    A material that scatters light in all directions
    """
    def __init__(self, a: Color):
        self._albedo = a

    def scatter(self, r_in: Ray,
                    rec: HitRecord,
                    attenuation: Color,
                    scattered: Ray) -> tuple[bool, Color, Ray]:
        scatter_direction = rec.normal + random_unit_vector()
        if scatter_direction.near_zero():
            scatter_direction = rec.normal

        scattered = Ray(rec.p, scatter_direction)
        attenuation = self._albedo
        return (True, attenuation, scattered)

class Metal(Material):
    """
    A material that reflects light
    """
    def __init__(self, a: Color, f: float):
        self._albedo = a
        self._fuzz = min(f, 1.0)

    def scatter(self, r_in: Ray,
                    rec: HitRecord,
                    attenuation: Color,
                    scattered: Ray) -> tuple[bool, Color, Ray]:
        reflected = r_in.direction.unit_vector().reflect(rec.normal)
        scattered = Ray(rec.p, reflected + self._fuzz * random_unit_vector())
        attenuation = self._albedo
        return (scattered.direction.dot(rec.normal) > 0, attenuation, scattered)


# class Dielectric(Material):
#     raise NotImplementedError("Dielectric class not implemented")
