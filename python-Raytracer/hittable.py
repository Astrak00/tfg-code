import math
from vector import Vector

class HitRecord:
    def __init__(self):
        self.point = Vector()
        self.normal = Vector()
        self.material = None
        self.t = 0.0
        self.front_face = False
    
    def set_face_normal(self, ray, outward_normal):
        self.front_face = ray.direction.dot(outward_normal) < 0
        self.normal = outward_normal if self.front_face else -outward_normal

class Hittable:
    def hit(self, ray, t_min, t_max, hit_record):
        pass

class HittableList(Hittable):
    def __init__(self):
        self.objects = []
    
    def add(self, obj):
        self.objects.append(obj)
    
    def clear(self):
        self.objects.clear()
    
    def hit(self, ray, t_min, t_max, hit_record):
        temp_record = HitRecord()
        hit_anything = False
        closest_so_far = t_max
        
        for obj in self.objects:
            if obj.hit(ray, t_min, closest_so_far, temp_record):
                hit_anything = True
                closest_so_far = temp_record.t
                hit_record.point = temp_record.point
                hit_record.normal = temp_record.normal
                hit_record.t = temp_record.t
                hit_record.front_face = temp_record.front_face
                hit_record.material = temp_record.material
        
        return hit_anything

class Sphere(Hittable):
    def __init__(self, center, radius, material):
        self.center = center
        self.radius = radius
        self.material = material
    
    def hit(self, ray, t_min, t_max, hit_record):
        oc = ray.origin - self.center
        a = ray.direction.dot(ray.direction)
        half_b = oc.dot(ray.direction)
        c = oc.dot(oc) - self.radius * self.radius
        
        discriminant = half_b * half_b - a * c
        if discriminant < 0:
            return False
        
        sqrtd = math.sqrt(discriminant)
        
        # Find the nearest root that lies in the acceptable range
        root = (-half_b - sqrtd) / a
        if root < t_min or t_max < root:
            root = (-half_b + sqrtd) / a
            if root < t_min or t_max < root:
                return False
        
        hit_record.t = root
        hit_record.point = ray.point_at(hit_record.t)
        outward_normal = (hit_record.point - self.center) / self.radius
        hit_record.set_face_normal(ray, outward_normal)
        hit_record.material = self.material
        
        return True
