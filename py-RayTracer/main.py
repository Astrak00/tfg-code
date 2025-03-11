"""
    This is the main file for the Ray Tracing in One Weekend book.    
"""
import gc

from random import random
from hittable_list import HittableList
from material import Lambertian, Metal
from color import Color
from sphere import Sphere
from camera import Camera
from vec3 import Vec3, Point3


if __name__ == "__main__":
    gc.disable()
    gound_material = Lambertian(Color(0.5, 0.5, 0.5))

    sphere = Sphere(Point3(0, -1000, 0), 1000, gound_material)

    world = HittableList(sphere)

    for a in range (-11, 11):
        for b in range (-11, 11):
            choose_mat = random()
            center = Point3(a + 0.9*random(), 0.2, b + 0.9*random())

            if (center - Point3(4, 0.2, 0)).length() > 0.9:
                if choose_mat < 0.8:
                    # diffuse
                    albedo = Color(random()*random(), random()*random(), random()*random())
                    sphere = Sphere(center, 0.2, Lambertian(albedo))
                    world.add(sphere)
                else: # choose_mat < 0.95:
                    # metal
                    albedo = Color(0.5*(1 + random()), 0.5*(1 + random()), 0.5*(1 + random()))
                    fuzz = 0.5*random()
                    sphere = Sphere(center, 0.2, Metal(albedo, fuzz))
                    world.add(sphere)
                # else:
                #     # glass
                #     sphere = Sphere(center, 0.2, Dielectric(1.5))
                #     world.add(sphere)


    material2 = Lambertian(Color(0.4, 0.2, 0.1))
    material3 = Metal(Color(0.7, 0.6, 0.5), 0.0)

    world.add(Sphere(Point3(0, 1, 0), 1.0, material2))
    world.add(Sphere(Point3(-4, 1, 0), 1.0, material3))
    world.add(Sphere(Point3(4, 1, 0), 1.0, material3))

    camera = Camera()

    camera.aspect_ratio = 16.0 / 9.0
    camera.image_width = 400
    camera.samples_per_pixel = 10
    camera.max_depth = 20

    camera.vfov = 20.0
    camera.lookfrom = Point3(13, 2, 3)
    camera.lookat = Point3(0, 0, 0)
    camera.vup = Vec3(0, 1, 0)

    camera.defocus_angle = 0.6
    camera.focus_distance = 10

    camera.render(world)
