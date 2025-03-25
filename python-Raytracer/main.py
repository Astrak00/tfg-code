import random
import math
import os
import argparse
import concurrent.futures
from vector import Vector
from ray import Ray
from hittable import HittableList, Sphere, HitRecord
from material import Lambertian, Metal, Dielectric
from camera import Camera

def ray_color(ray, world, depth) -> Vector:
    hit_record = HitRecord()
    
    # If we've exceeded the ray bounce limit, no more light is gathered
    if depth <= 0:
        return Vector(0, 0, 0)
    
    # 0.001 is an epsilon value to avoid shadow acne
    if world.hit(ray, 0.001, float('inf'), hit_record):
        scattered = Ray()
        attenuation = Vector()

        success, scattered, attenuation = hit_record.material.scatter(ray, hit_record)
        if success:
            return attenuation * ray_color(scattered, world, depth-1)
        return Vector(0, 0, 0)

    # Background - a simple gradient
    unit_direction = ray.direction.normalize()
    t = 0.5 * (unit_direction.y + 1.0)
    return Vector(1.0, 1.0, 1.0) * (1.0-t) + Vector(0.5, 0.7, 1.0) * t

def random_scene():
    with open("random_scene.txt", "w") as f:
        world = HittableList()
        
        ground_material = Lambertian(Vector(0.5, 0.5, 0.5))
        world.add(Sphere(Vector(0, -1000, 0), 1000, ground_material))
        
        for a in range(-11, 11):
            for b in range(-11, 11):
                choose_mat = random.random()
                center = Vector(a + 0.9 * random.random(), 0.2, b + 0.9 * random.random())
                
                if (center - Vector(4, 0.2, 0)).length() > 0.9:
                    if choose_mat < 0.8:
                        # Diffuse
                        albedo = Vector(random.random(), random.random(), random.random()) * \
                                Vector(random.random(), random.random(), random.random())
                        sphere_material = Lambertian(albedo)
                        world.add(Sphere(center, 0.2, sphere_material))
                        # Write sphere info to file
                        f.write(f"{center.x} {center.y} {center.z} 0.2 lambertian {albedo.x} {albedo.y} {albedo.z}\n")
                    elif choose_mat < 0.95:
                        # Metal
                        albedo = Vector(random.uniform(0.5, 1), random.uniform(0.5, 1), random.uniform(0.5, 1))
                        fuzz = random.uniform(0, 0.5)
                        sphere_material = Metal(albedo, fuzz)
                        world.add(Sphere(center, 0.2, sphere_material))
                        f.write(f"{center.x} {center.y} {center.z} 0.2 metal {albedo.x} {albedo.y} {albedo.z} {fuzz}\n")
                    else:
                        # Glass
                        sphere_material = Dielectric(1.5)
                        world.add(Sphere(center, 0.2, sphere_material))
                        f.write(f"{center.x} {center.y} {center.z} 0.2 dielectric 1.5\n")
    
    material1 = Dielectric(1.5)
    world.add(Sphere(Vector(0, 1, 0), 1.0, material1))
    
    material2 = Lambertian(Vector(0.4, 0.2, 0.1))
    world.add(Sphere(Vector(-4, 1, 0), 1.0, material2))
    
    material3 = Metal(Vector(0.7, 0.6, 0.5), 0.0)
    world.add(Sphere(Vector(4, 1, 0), 1.0, material3))
    
    return world


def create_world_from_file(filepath):
    world = HittableList()

    # Add ground sphere
    ground_material = Lambertian(Vector(0.5, 0.5, 0.5))
    world.add(Sphere(Vector(0, -1000, 0), 1000, ground_material))

    try:
        with open(filepath, 'r', encoding="utf-8") as file:
            for line in file:
                # Skip empty lines and comments
                if not line.strip() or line.strip().startswith('#'):
                    continue

                parts = line.strip().split()
                if len(parts) < 5:  # At minimum we need x, y, z, radius, material_type
                    continue

                try:
                    x, y, z = float(parts[0]), float(parts[1]), float(parts[2])
                    radius = float(parts[3])
                    material_type = parts[4]

                    if material_type == "lambertian" and len(parts) >= 8:
                        r, g, b = float(parts[5]), float(parts[6]), float(parts[7])
                        material = Lambertian(Vector(r, g, b))
                    elif material_type == "metal" and len(parts) >= 9:
                        r, g, b = float(parts[5]), float(parts[6]), float(parts[7])
                        fuzz = float(parts[8])
                        material = Metal(Vector(r, g, b), fuzz)
                    elif material_type == "dielectric" and len(parts) >= 6:
                        index = float(parts[5])
                        material = Dielectric(index)
                    else:
                        # Skip if material parameters are invalid
                        continue

                    world.add(Sphere(Vector(x, y, z), radius, material))
                except (ValueError, IndexError):
                    # Skip lines with invalid values
                    continue

        # print(f"Loaded world from {filepath}")

    except FileNotFoundError:
        print(f"Error: File {filepath} not found. Generating random scene instead.", flush=True)
        return random_scene()

    return world


def render_pixel(params):
    i, j, image_width, image_height, samples_per_pixel, max_depth, camera, world = params
    pixel_color = Vector(0, 0, 0)
    for _ in range(samples_per_pixel):
        u = (i + random.random()) / (image_width - 1)
        v = (j + random.random()) / (image_height - 1)
        ray = camera.get_ray(u, v)
        pixel_color += ray_color(ray, world, max_depth)
    
    # Divide the color by the number of samples and gamma-correct for gamma=2.0
    scale = 1.0 / samples_per_pixel
    r = math.sqrt(scale * pixel_color.x)
    g = math.sqrt(scale * pixel_color.y)
    b = math.sqrt(scale * pixel_color.z)
    
    # Return the color as a string
    return (j, i, f"{int(256 * max(0, min(0.999, r)))} "
          f"{int(256 * max(0, min(0.999, g)))} "
          f"{int(256 * max(0, min(0.999, b)))}")


def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Ray Tracer')
    parser.add_argument('--path', type=str, default="sphere_data.txt", 
                        help='Path to the sphere data file (default: sphere_data.txt)')
    args = parser.parse_args()

    # Image
    aspect_ratio = 16.0 / 9.0
    image_width = 800
    image_height = int(image_width / aspect_ratio)
    samples_per_pixel = 50
    max_depth = 50

    # World - either loaded from file or randomly generated
    if os.path.exists(args.path):
        world = create_world_from_file(args.path)
    else:
        print(f"File {args.path} not found. Generating random scene instead.")
        world = random_scene()

    # Camera
    lookfrom = Vector(13, 2, 3)
    lookat = Vector(0, 0, 0)
    vup = Vector(0, 1, 0)
    dist_to_focus = 10.0
    aperture = 0.6

    camera = Camera(lookfrom, lookat, vup, 20, aspect_ratio, aperture, dist_to_focus)

    # Determine whether to use multithreading
    multithreading = os.environ.get('MULTITHREADING', '') != ''
    num_threads = os.cpu_count() if multithreading else 1

    # Render
    print(f"P3\n{image_width} {image_height}\n255")
    pixel_string = ""

    if num_threads > 1:
        # Multithreaded rendering
        pixels = []
        with concurrent.futures.ProcessPoolExecutor(max_workers=num_threads) as executor:
            # Prepare parameters for all pixels
            pixel_params = []
            for j in range(image_height-1, -1, -1):
                for i in range(image_width):
                    pixel_params.append((i, j, image_width, image_height, samples_per_pixel, max_depth, camera, world))
            
            # Process pixels in parallel and collect results
            pixels = list(executor.map(render_pixel, pixel_params))
        
        # Sort the pixels by their position (j, i) and print them in order
        pixels.sort()  # Will sort by j (row) first, then by i (column)
        for _, _, color_str in pixels:
            print(color_str)

    else:
        # Single-threaded rendering (original code)
        for j in range(image_height-1, -1, -1):
            for i in range(image_width):
                pixel_color = Vector(0, 0, 0)
                for _ in range(samples_per_pixel):
                    u = (i + random.random()) / (image_width - 1)
                    v = (j + random.random()) / (image_height - 1)
                    ray = camera.get_ray(u, v)
                    pixel_color += ray_color(ray, world, max_depth)
                
                # Divide the color by the number of samples and gamma-correct for gamma=2.0
                r = pixel_color.x
                g = pixel_color.y
                b = pixel_color.z
                
                scale = 1.0 / samples_per_pixel
                r = math.sqrt(scale * r)
                g = math.sqrt(scale * g)
                b = math.sqrt(scale * b)
                
                # Write the translated [0,255] value of each color component
                pixel_string += f"{int(256 * max(0, min(0.999, r)))} {int(256 * max(0, min(0.999, g)))} {int(256 * max(0, min(0.999, b)))}"

        print(pixel_string)
if __name__ == "__main__":
    # The python version blurs too much.
    main()
