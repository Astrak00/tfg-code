from interval import Interval
from ray import Ray
from hittable import Hittable, HitRecord
from vec3 import Point3, Vec3

class HittableList(Hittable):
    def __init__(self, hittable_object: Hittable):
        self.objects: list[Hittable] = [hittable_object]

    def clear(self):
        """
        Empty the list of hittable objects
        """
        self.objects.clear()

    def add(self, hittable_object: Hittable):
        """
        Add a hittable object to the list
        """
        self.objects.append(hittable_object)

    def hit(self, r: Ray, ray_t: Interval, rec: HitRecord) -> bool:
        temp_rec = HitRecord()

        hit_anything = False
        closest_so_far = ray_t.max_val

        for obj in self.objects:
            if obj.hit(r, Interval(ray_t.min_val, closest_so_far), temp_rec):
                hit_anything = True
                closest_so_far = temp_rec.t
                rec.t = temp_rec.t
                rec.p = temp_rec.p
                rec.normal = temp_rec.normal
                rec.material = temp_rec.material
        return hit_anything