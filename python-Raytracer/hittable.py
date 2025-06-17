import math
from vec3 import dot, Point3, Vec3
from utils import Interval
from ray import Ray
from utils import Interval
from material import Lambertian, Metal, Dielectric

class HitRecord:
    def __init__(self):
        self.p = Point3()
        self.normal = Vec3()
        self.mat = None
        self.t = 0.0
        self.front_face = False

    def set_face_normal(self, r: Ray, outward_normal: Vec3) -> None:
        self.front_face = dot(r.direction, outward_normal) < 0
        self.normal = outward_normal if self.front_face else -outward_normal


class Hittable:
    def hit(self, r: Ray, ray_t: Interval, rec: HitRecord) -> bool:
        """Returns True if hit, updates rec"""
        pass


class HittableList(Hittable):
    def __init__(self):
        self.objects = []

    def add(self, obj: 'Sphere') -> None:
        self.objects.append(obj)

    def hit(self, r: Ray, ray_t: Interval, rec: HitRecord) -> bool:
        hit_anything = False
        closest_so_far = ray_t.max

        for obj in self.objects:
            temp_interval = Interval(ray_t.min, closest_so_far)
            if obj.hit(r, temp_interval, rec):
                hit_anything = True
                closest_so_far = rec.t

        return hit_anything


class Sphere(Hittable):
    def __init__(self, center: Vec3, radius: float, material: Lambertian | Metal | Dielectric):
        self.center = center
        self.radius = radius
        self.material = material

    def hit(self, r: Ray, ray_t: Interval, rec: HitRecord) -> bool:
        oc = r.origin - self.center
        a = r.direction.length_squared()
        half_b = dot(oc, r.direction)
        c = oc.length_squared() - self.radius * self.radius

        discriminant = half_b * half_b - a * c
        if discriminant < 0:
            return False

        sqrtd = math.sqrt(discriminant)

        # Find the nearest root in the acceptable range
        root = (-half_b - sqrtd) / a
        if not ray_t.contains(root):
            root = (-half_b + sqrtd) / a
            if not ray_t.contains(root):
                return False

        rec.t = root
        rec.p = r.at(rec.t)
        outward_normal = (rec.p - self.center) / self.radius
        rec.set_face_normal(r, outward_normal)
        rec.mat = self.material

        return True
