import math
import sys
from concurrent.futures import ProcessPoolExecutor

from ray import Ray
from vec3 import Color, Point3, Vec3, cross, random_in_unit_disk, unit_vector
from utils import degrees_to_radians, random_double, INFINITY, Interval
from image import Image
from hittable import HitRecord


class Camera:
    def __init__(self):
        # Public fields
        self.aspect_ratio = 1.0
        self.image_width = 100
        self.samples_per_pixel = 10
        self.max_depth = 10
        self.vfov = 90.0
        self.look_from = Point3(0.0, 0.0, 0.0)
        self.look_at = Point3(0.0, 0.0, -1.0)
        self.vup = Vec3(0.0, 1.0, 0.0)
        self.defocus_angle = 0.0
        self.focus_dist = 10.0

        # Private fields - will be initialized later
        self.image_height = 0
        self.pixel_samples_scale = 0.0
        self.center = Point3(0.0, 0.0, 0.0)
        self.pixel00_loc = Point3(0.0, 0.0, 0.0)
        self.pixel_delta_u = Vec3(0.0, 0.0, 0.0)
        self.pixel_delta_v = Vec3(0.0, 0.0, 0.0)
        self.u = Vec3(0.0, 0.0, 0.0)
        self.v = Vec3(0.0, 0.0, 0.0)
        self.w = Vec3(0.0, 0.0, 0.0)
        self.defocus_disk_u = Vec3(0.0, 0.0, 0.0)
        self.defocus_disk_v = Vec3(0.0, 0.0, 0.0)

    def __str__(self):
        return (
            f"Camera(aspect_ratio={self.aspect_ratio}\n "
            f"width={self.image_width}\n "
            f"samples_per_pixel={self.samples_per_pixel}\n "
            f"max_depth={self.max_depth}\n "
            f"vfov={self.vfov}\n "
            f"look_from={self.look_from}\n "
            f"look_at={self.look_at}\n "
            f"vup={self.vup}\n "
            f"defocus_angle={self.defocus_angle}\n "
            f"focus_dist={self.focus_dist}\n "
        )

    def initialize(self):
        # Calculate image height
        self.image_height = max(1, int(self.image_width / self.aspect_ratio))

        self.pixel_samples_scale = 1.0 / self.samples_per_pixel
        self.center = self.look_from

        # Determine viewport dimensions
        theta = degrees_to_radians(self.vfov)
        h = math.tan(theta / 2.0)
        viewport_height = 2.0 * h * self.focus_dist
        viewport_width = viewport_height * (self.image_width / self.image_height)

        # Calculate the u,v,w unit basis vectors for the camera coordinate frame
        self.w = unit_vector(self.look_from - self.look_at)
        self.u = unit_vector(cross(self.vup, self.w))
        self.v = cross(self.w, self.u)

        # Calculate vectors across the horizontal and down the vertical viewport edges
        viewport_u = self.u * viewport_width
        viewport_v = self.v * -viewport_height

        # Calculate horizontal and vertical delta vectors from pixel to pixel
        self.pixel_delta_u = viewport_u / self.image_width
        self.pixel_delta_v = viewport_v / self.image_height

        # Calculate the location of the upper left pixel
        viewport_upper_left = (
            self.center - self.w * self.focus_dist - viewport_u / 2.0 - viewport_v / 2.0
        )
        self.pixel00_loc = (
            viewport_upper_left + (self.pixel_delta_u + self.pixel_delta_v) * 0.5
        )

        # Calculate the camera defocus disk basis vectors
        defocus_radius = self.focus_dist * math.tan(
            degrees_to_radians(self.defocus_angle / 2.0)
        )
        self.defocus_disk_u = self.u * defocus_radius
        self.defocus_disk_v = self.v * defocus_radius

    def get_ray(self, i, j):
        """Get a randomly sampled camera ray for the pixel at location i,j"""
        offset = self.sample_square()
        pixel_sample = (
            self.pixel00_loc
            + self.pixel_delta_u * (i + offset.x())
            + self.pixel_delta_v * (j + offset.y())
        )

        ray_origin = (
            self.center if self.defocus_angle <= 0.0 else self.defocus_disk_sample()
        )
        ray_direction = pixel_sample - ray_origin

        return Ray(ray_origin, ray_direction)

    def sample_square(self):
        """Returns a random point in the [-0.5,0.5] x [-0.5,0.5] square"""
        return Vec3(random_double() - 0.5, random_double() - 0.5, 0.0)

    def defocus_disk_sample(self):
        """Returns a random point in the camera defocus disk"""
        p = random_in_unit_disk()
        return self.center + self.defocus_disk_u * p.x() + self.defocus_disk_v * p.y()

    def ray_color(self, r, depth, world):
        """Calculate the color for a ray"""
        # Base case: ray bounce limit reached
        if depth <= 0:
            return Color(0.0, 0.0, 0.0)

        rec = HitRecord()

        if world.hit(r, Interval(0.001, INFINITY), rec):
            scatter_happened, attenuation, scattered = rec.mat.scatter(r, rec)
            if scatter_happened:
                return attenuation * self.ray_color(scattered, depth - 1, world)
            return Color(0.0, 0.0, 0.0)

        # Background - a simple gradient
        unit_direction = unit_vector(r.direction)
        a = 0.5 * (unit_direction.y() + 1.0)
        return Color(1.0, 1.0, 1.0) * (1.0 - a) + Color(0.5, 0.7, 1.0) * a

    def process_row(self, j, world):
        """Process a single row of the image"""
        row_pixels = [Color(0.0, 0.0, 0.0) for _ in range(self.image_width)]

        for i in range(self.image_width):
            pixel_color = Color(0.0, 0.0, 0.0)
            for _ in range(self.samples_per_pixel):
                r = self.get_ray(i, j)
                pixel_color = pixel_color + self.ray_color(r, self.max_depth, world)
            row_pixels[i] = pixel_color * self.pixel_samples_scale

        return j, row_pixels

    def render(self, world, out_stream, num_threads=1):
        """Render the scene to the output stream"""
        self.initialize()

        # Create image data
        img = Image(self.image_width, self.image_height)

        print(f"Rendering with {num_threads} threads")

        if num_threads <= 1:
            # Single-threaded rendering
            for j in range(self.image_height):
                print(
                    f"\rScanlines remaining: {self.image_height - j} ",
                    end=""
                )
                sys.stderr.flush()

                for i in range(self.image_width):
                    pixel_color = Color(0.0, 0.0, 0.0)
                    for _ in range(self.samples_per_pixel):
                        r = self.get_ray(i, j)
                        pixel_color = pixel_color + self.ray_color(
                            r, self.max_depth, world
                        )
                    img.set_pixel(i, j, pixel_color * self.pixel_samples_scale)
        else:
            # Multi-threaded rendering
            with ProcessPoolExecutor(max_workers=num_threads) as executor:
                # Submit tasks for each row
                futures = [
                    executor.submit(self.process_row, j, world)
                    for j in range(self.image_height)
                ]

                # Process results as they become available
                total_rows = self.image_height
                processed_rows = 0

                for future in futures:
                    j, row_pixels = future.result()
                    processed_rows += 1

                    print(
                        f"\rScanlines remaining: {total_rows - processed_rows} ",
                        end=""
                    )
                    sys.stderr.flush()

                    for i in range(self.image_width):
                        img.set_pixel(i, j, row_pixels[i])

        print("\rScanlines remaining: 0 ", end="")

        # Write the image to the output stream
        img.write_to(out_stream)

        print("\rDone.                 ")
        return True
