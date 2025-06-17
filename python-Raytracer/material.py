import random
import math
from ray import Ray
from vec3 import dot, random_unit_vector, reflect, refract, unit_vector, Color
from hittable import HitRecord

class Material:
    def scatter(self, r_in: Ray, rec: HitRecord) -> tuple[bool, Color, Ray]:
        """Returns (scatter_happened, attenuation, scattered_ray)"""
        pass


class Lambertian(Material):
    def __init__(self, albedo: Color):
        self.albedo = albedo

    def scatter(self, r_in: Ray, rec: HitRecord) -> tuple[bool, Color, Ray]:
        scatter_direction = rec.normal + random_unit_vector()

        # Catch degenerate scatter direction
        if scatter_direction.near_zero():
            scatter_direction = rec.normal

        scattered = Ray(rec.p, scatter_direction)
        return True, self.albedo, scattered


class Metal(Material):
    def __init__(self, albedo: Color, fuzz=0.0):
        self.albedo = albedo
        self.fuzz = min(fuzz, 1.0)

    def scatter(self, r_in: Ray, rec: HitRecord) -> tuple[bool, Color, Ray]:
        reflected = reflect(r_in.direction, rec.normal)
        scattered = Ray(rec.p, unit_vector(reflected) + random_unit_vector() * self.fuzz)
        scatter_happened = dot(scattered.direction, rec.normal) > 0
        return scatter_happened, self.albedo, scattered


class Dielectric(Material):
    def __init__(self, index_of_refraction: float):
        self.ir = index_of_refraction

    def reflectance(self, cosine: float, ref_idx: float) -> float:
        """Use Schlick's approximation for reflectance"""
        r0 = (1.0 - ref_idx) / (1.0 + ref_idx)
        r0 = r0 * r0
        return r0 + (1.0 - r0) * ((1.0 - cosine) ** 5)

    def scatter(self, r_in: Ray, rec: HitRecord) -> tuple[bool, Color, Ray]:
        attenuation = Color(1.0, 1.0, 1.0)
        refraction_ratio = 1.0 / self.ir if rec.front_face else self.ir

        unit_direction = unit_vector(r_in.direction)
        cos_theta = min(dot(-unit_direction, rec.normal), 1.0)
        sin_theta = math.sqrt(1.0 - cos_theta * cos_theta)

        cannot_refract = refraction_ratio * sin_theta > 1.0
        will_reflect = self.reflectance(cos_theta, refraction_ratio) > random.random()

        if cannot_refract or will_reflect:
            direction = reflect(unit_direction, rec.normal)
        else:
            direction = refract(unit_direction, rec.normal, refraction_ratio)

        scattered = Ray(rec.p, direction)
        return True, attenuation, scattered
