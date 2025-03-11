"""
A module that contains a camera class that renders a scene.
"""
import math
import random
import sys

from ray import Ray
from interval import Interval
from vec3 import Vec3, Point3, random_in_unit_disk
from image import Image
from hittable import Hittable, HitRecord
from color import Color
from rtweekend import degrees_to_radians


class Camera():
    """
    A camera class that renders a scene.
    """
    def __init__(self):
        self.aspect_ratio: float = 1.0
        self.image_width: int = 100
        self.samples_per_pixel: int = 10
        self.max_depth: int = 10

        self.vfov: float = 90.0
        self.lookfrom: Vec3 = Vec3(0, 0, 0)
        self.lookat: Vec3 = Vec3(0, 0, -1)
        self.vup: Vec3 = Vec3(0, 1, 0)

        self.defocus_angle: int = 0
        self.focus_distance: int = 10

        self._pixel_samples_scale: float
        self._image_height: int
        self._center: Point3
        self._pixel00_loc: Point3
        self._pixel_delta_u: Vec3
        self._pixel_delta_v: Vec3
        self._w: Vec3
        self._defocus_disk_u: Vec3
        self._defocus_disk_v: Vec3

    def render(self, world: Hittable):
        """
        Render the scene.
        """
        self.initialize()

        image = Image(self.image_width, self._image_height)

        processed_lines = 0

        for j in range(self._image_height):
            print(f"\r\033[KProcessing: {processed_lines / self._image_height * 100:.2f}%",
                    end="", file=sys.stderr)
            for i in range(self.image_width):
                pixel_color = Vec3(0, 0, 0)
                for _ in range(self.samples_per_pixel):
                    r = self.get_ray(i, j)
                    pixel_color += self.ray_color(r, self.max_depth, world)
                image.set_pixel(i, j, pixel_color * self._pixel_samples_scale)
            processed_lines += 1

        image.write("output.ppm", print_output=True)

    def get_ray(self, i: int, j: int) -> Ray:
        """
        Construct a camera ray originating from the defocus disk and directed at a randomly
        sampled point around the pixel location i, j.
        """
        offset = self.sample_square()
        pixel_sample = self._pixel00_loc + (
            ((i + offset.x()) * self._pixel_delta_u) +
            ((j + offset.y()) * self._pixel_delta_v))

        ray_origin = self._center if self.defocus_angle <= 0 else self.defocus_disk_sample()
        ray_direction = pixel_sample - ray_origin

        return Ray(ray_origin, ray_direction)

    def initialize(self):
        """
        Initialize the camera.
        """
        self._image_height = int(self.image_width / self.aspect_ratio)
        self._image_height = self._image_height if self._image_height >= 1 else 1

        self._pixel_samples_scale = 1.0 / self.samples_per_pixel

        self._center = self.lookfrom

        # Viewport dimensions
        theta = degrees_to_radians(self.vfov)
        h = math.tan(theta / 2)
        viewport_height = 2.0 * h * self.focus_distance
        viewport_width = viewport_height * self.image_width / self._image_height

        w = (self.lookfrom - self.lookat).unit_vector()
        u = self.vup.cross(w).unit_vector()
        v = w.cross(u)

        viewport_u = u * viewport_width
        viewport_v = -v * viewport_height

        self._pixel_delta_u = viewport_u / self.image_width
        self._pixel_delta_v = viewport_v / self._image_height

        viewport_upper_left = self._center - ((self.focus_distance * w) +
                                              (viewport_u / 2) - (viewport_v / 2))
        self._pixel00_loc = viewport_upper_left + 0.5 * (self._pixel_delta_u - self._pixel_delta_v)

        defocus_radius = self.focus_distance * math.tan(degrees_to_radians(self.defocus_angle) / 2)
        self._defocus_disk_u = u * defocus_radius
        self._defocus_disk_v = v * defocus_radius


    def ray_color(self, r: Ray, depth: int, world: Hittable) -> Color:
        """
        Construct a camera ray originating from the defocus disk and directed at a randomly
        sampled point around the pixel location i, j.
        """
        if depth <= 0:
            return Color(0, 0, 0)

        rec = HitRecord()

        if world.hit(r, Interval(0.001, math.inf), rec):
            scattered: Ray = Ray(Point3(0, 0, 0), Vec3(0, 0, 0))
            attenuation = Color(0, 0, 0)
            sct_bool, attenuation, scattered = rec.material.scatter(r, rec, attenuation, scattered)
            if sct_bool:
                return attenuation * self.ray_color(scattered, depth - 1, world)
            return Color(0, 0, 0)

        unit_direction = r.direction.unit_vector()
        a = 0.5 * (unit_direction.y() + 1.0)
        return (1.0 - a) * Color(1.0, 1.0, 1.0) + a * Color(0.5, 0.7, 1.0)


    def sample_square(self) -> Vec3:
        """Returns the vector to a random point in the [-.5,-.5]-[+.5,+.5] unit square."""
        return Vec3(random.random() - 0.5, random.random() - 0.5, 0)

    def defocus_disk_sample(self) -> Point3:
        """Returns a point on the defocus disk."""
        p = random_in_unit_disk()
        return self._center + (p.x() * self._defocus_disk_u) + (p.y() * self._defocus_disk_v)
