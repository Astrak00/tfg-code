import math
import random
from vector import Vector
from ray import Ray

class Material:
    def scatter(self, ray_in, hit_record):
        pass

class Lambertian(Material):
    def __init__(self, albedo):
        self.albedo = albedo
    
    def scatter(self, ray_in, hit_record):
        scatter_direction = hit_record.normal + random_in_unit_sphere()
        
        # Catch degenerate scatter direction
        if (abs(scatter_direction.x) < 1e-8 and 
            abs(scatter_direction.y) < 1e-8 and 
            abs(scatter_direction.z) < 1e-8):
            scatter_direction = hit_record.normal
            
        scattered_ray = Ray(hit_record.point, scatter_direction)
        attenuation = self.albedo
        return True, scattered_ray, attenuation

class Metal(Material):
    def __init__(self, albedo, fuzz=0.0):
        self.albedo = albedo
        self.fuzz = min(fuzz, 1.0)
    
    def scatter(self, ray_in, hit_record):
        reflected = ray_in.direction.reflect(hit_record.normal)
        scattered_ray = Ray(hit_record.point, reflected + self.fuzz * random_in_unit_sphere())
        attenuation = self.albedo
        return scattered_ray.direction.dot(hit_record.normal) > 0, scattered_ray, attenuation

class Dielectric(Material):
    def __init__(self, refractive_index):
        self.refractive_index = refractive_index
    
    def scatter(self, ray_in, hit_record):
        attenuation = Vector(1.0, 1.0, 1.0)
        
        if hit_record.front_face:
            refraction_ratio = 1.0 / self.refractive_index
        else:
            refraction_ratio = self.refractive_index
            
        unit_direction = ray_in.direction.normalize()
        
        cos_theta = min(-unit_direction.dot(hit_record.normal), 1.0)
        sin_theta = math.sqrt(1.0 - cos_theta * cos_theta)
        
        cannot_refract = refraction_ratio * sin_theta > 1.0
        
        if cannot_refract or self.reflectance(cos_theta, refraction_ratio) > random.random():
            direction = unit_direction.reflect(hit_record.normal)
        else:
            direction = self.refract(unit_direction, hit_record.normal, refraction_ratio)
            
        scattered_ray = Ray(hit_record.point, direction)
        return True, scattered_ray, attenuation
    
    def refract(self, uv, n, etai_over_etat):
        cos_theta = min(-uv.dot(n), 1.0)
        r_out_perp = etai_over_etat * (uv + cos_theta * n)
        r_out_parallel = -math.sqrt(abs(1.0 - r_out_perp.length()**2)) * n
        return r_out_perp + r_out_parallel
    
    def reflectance(self, cosine, ref_idx):
        # Use Schlick's approximation for reflectance
        r0 = (1 - ref_idx) / (1 + ref_idx)
        r0 = r0 * r0
        return r0 + (1 - r0) * math.pow((1 - cosine), 5)

def random_in_unit_sphere():
    while True:
        p = Vector(random.uniform(-1, 1), random.uniform(-1, 1), random.uniform(-1, 1))
        if p.length() * p.length() < 1:
            return p

def random_unit_vector():
    return random_in_unit_sphere().normalize()
