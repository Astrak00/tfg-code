import sys
import os
import multiprocessing

from vec3 import Vec3, Point3, Color
from hittable import HittableList, Sphere
from material import Lambertian, Metal, Dielectric
from camera import Camera
from utils import random_double


def create_world_from_file(filepath):
    """Create world from a scene description file"""
    world = HittableList()
    cam = Camera()

    # Add ground sphere
    ground_material = Lambertian(Color(0.5, 0.5, 0.5))
    world.add(Sphere(Point3(0.0, -1000.0, 0.0), 1000.0, ground_material))

    # Read spheres from file
    try:
        with open(filepath, "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                # Skip empty lines and comments
                if not line or line.startswith("#"):
                    continue

                parts = line.split()
                
                # Check if this is a camera parameter
                if line.startswith("c ") and len(parts) >= 3:
                    param_name = parts[1]
                    if param_name == "ratio" and len(parts) >= 4:
                        cam.aspect_ratio = float(parts[2]) / float(parts[3])
                    elif param_name == "width" and len(parts) >= 3:
                        cam.image_width = int(parts[2])
                    elif param_name == "samplesPerPixel" and len(parts) >= 3:
                        cam.samples_per_pixel = int(parts[2])
                    elif param_name == "maxDepth" and len(parts) >= 3:
                        cam.max_depth = int(parts[2])
                    elif param_name == "vfov" and len(parts) >= 3:
                        cam.vfov = float(parts[2])
                    elif param_name == "lookFrom" and len(parts) >= 5:
                        cam.look_from = Point3(float(parts[2]), float(parts[3]), float(parts[4]))
                    elif param_name == "lookAt" and len(parts) >= 5:
                        cam.look_at = Point3(float(parts[2]), float(parts[3]), float(parts[4]))
                    elif param_name == "vup" and len(parts) >= 5:
                        cam.vup = Vec3(float(parts[2]), float(parts[3]), float(parts[4]))
                    elif param_name == "defocusAngle" and len(parts) >= 3:
                        cam.defocus_angle = float(parts[2])
                    elif param_name == "focusDist" and len(parts) >= 3:
                        cam.focus_dist = float(parts[2])
                    continue

                if len(parts) < 5:
                    continue  # Need at least x, y, z, radius, material_type

                # Parse coordinates and radius
                x = float(parts[0]) if parts[0] else 0.0
                y = float(parts[1]) if parts[1] else 0.0
                z = float(parts[2]) if parts[2] else 0.0
                radius = float(parts[3]) if parts[3] else 0.2
                material_type = parts[4]

                center = Point3(x, y, z)

                # Parse material based on type
                if material_type == "lambertian" and len(parts) >= 8:
                    r = float(parts[5]) if parts[5] else 0.5
                    g = float(parts[6]) if parts[6] else 0.5
                    b = float(parts[7]) if parts[7] else 0.5
                    material = Lambertian(Color(r, g, b))
                    world.add(Sphere(center, radius, material))
                elif material_type == "metal" and len(parts) >= 9:
                    r = float(parts[5]) if parts[5] else 0.5
                    g = float(parts[6]) if parts[6] else 0.5
                    b = float(parts[7]) if parts[7] else 0.5
                    fuzz = float(parts[8]) if parts[8] else 0.0
                    material = Metal(Color(r, g, b), fuzz)
                    world.add(Sphere(center, radius, material))
                elif material_type == "dielectric" and len(parts) >= 6:
                    index = float(parts[5]) if parts[5] else 1.5
                    material = Dielectric(index)
                    world.add(Sphere(center, radius, material))
                else:
                    continue  # Skip invalid material types or insufficient parameters

        print(f"Loaded world from {filepath}", file=sys.stderr)
        return world, cam
    except (FileNotFoundError, IOError) as e:
        print(f"Error reading from {filepath}: {e}", file=sys.stderr)
        return None, None


def random_scene():
    """Generate a random scene with many spheres"""
    world = HittableList()

    # Ground
    ground_material = Lambertian(Color(0.5, 0.5, 0.5))
    world.add(Sphere(Point3(0.0, -1000.0, 0.0), 1000.0, ground_material))

    # Small random spheres
    for a in range(-11, 11):
        for b in range(-11, 11):
            choose_mat = random_double()
            center = Point3(a + 0.9 * random_double(), 0.2, b + 0.9 * random_double())

            if (center - Point3(4.0, 0.2, 0.0)).length() > 0.9:
                if choose_mat < 0.8:
                    # Diffuse
                    albedo = Color(
                        random_double() * random_double(),
                        random_double() * random_double(),
                        random_double() * random_double(),
                    )
                    sphere_material = Lambertian(albedo)
                    world.add(Sphere(center, 0.2, sphere_material))
                elif choose_mat < 0.95:
                    # Metal
                    albedo = Color(
                        0.5 * (1.0 + random_double()),
                        0.5 * (1.0 + random_double()),
                        0.5 * (1.0 + random_double()),
                    )
                    fuzz = 0.5 * random_double()
                    sphere_material = Metal(albedo, fuzz)
                    world.add(Sphere(center, 0.2, sphere_material))
                else:
                    # Glass
                    sphere_material = Dielectric(1.5)
                    world.add(Sphere(center, 0.2, sphere_material))

    # Three larger spheres
    material1 = Dielectric(1.5)
    world.add(Sphere(Point3(0.0, 1.0, 0.0), 1.0, material1))

    material2 = Lambertian(Color(0.4, 0.2, 0.1))
    world.add(Sphere(Point3(-4.0, 1.0, 0.0), 1.0, material2))

    material3 = Metal(Color(0.7, 0.6, 0.5), 0.0)
    world.add(Sphere(Point3(4.0, 1.0, 0.0), 1.0, material3))

    # After creating the random scene, also save it to a file
    try:
        with open("sphere_data.txt", "w", encoding="utf-8") as file:
            # Small spheres
            for a in range(-11, 11):
                for b in range(-11, 11):
                    choose_mat = random_double()
                    center = Point3(
                        a + 0.9 * random_double(), 0.2, b + 0.9 * random_double()
                    )

                    if (center - Point3(4.0, 0.2, 0.0)).length() > 0.9:
                        if choose_mat < 0.8:
                            # Diffuse
                            albedo = Color(
                                random_double() * random_double(),
                                random_double() * random_double(),
                                random_double() * random_double(),
                            )
                            file.write(
                                f"{center.x()} {center.y()} {center.z()} 0.2 lambertian {albedo.x()} {albedo.y()} {albedo.z()}\n"
                            )
                        elif choose_mat < 0.95:
                            # Metal
                            albedo = Color(
                                0.5 * (1.0 + random_double()),
                                0.5 * (1.0 + random_double()),
                                0.5 * (1.0 + random_double()),
                            )
                            fuzz = 0.5 * random_double()
                            file.write(
                                f"{center.x()} {center.y()} {center.z()} 0.2 metal {albedo.x()} {albedo.y()} {albedo.z()} {fuzz}\n"
                            )
                        else:
                            # Glass
                            file.write(
                                f"{center.x()} {center.y()} {center.z()} 0.2 dielectric 1.5\n"
                            )

            # Large spheres
            file.write("0.0 1.0 0.0 1.0 dielectric 1.5\n")
            file.write("-4.0 1.0 0.0 1.0 lambertian 0.4 0.2 0.1\n")
            file.write("4.0 1.0 0.0 1.0 metal 0.7 0.6 0.5 0.0\n")
    except (IOError, OSError) as e:
        print(f"Error writing scene to file: {e}", file=sys.stderr)

    return world


def main():
    """Main entry point for the ray tracer"""
    # Parse command line arguments
    filepath = "sphere_data.txt"
    output_path = "cpp_spheres.ppm"
    num_threads = multiprocessing.cpu_count()

    i = 1
    while i < len(sys.argv):
        if sys.argv[i] == "--path" and i + 1 < len(sys.argv):
            filepath = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--output" and i + 1 < len(sys.argv):
            output_path = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--cores" and i + 1 < len(sys.argv):
            try:
                num_threads = int(sys.argv[i + 1])
                if num_threads <= 0:
                    raise ValueError("Number of cores must be positive")
            except ValueError as e:
                print(f"Error: Invalid number of cores specified: {e}", file=sys.stderr)
                sys.exit(1)
            i += 2
        elif sys.argv[i] == "--help" or sys.argv[i] == "-h":
            print(f"Usage: {sys.argv[0]} [--path <sphere_data_path>] [--output <output_ppm_path>]")
            print(f"Default sphere data path: {filepath}")
            print("Default output: stdout")
            return
        else:
            print(f"Error: Unknown argument: {sys.argv[i]}", file=sys.stderr)
            print("Use --help for usage information", file=sys.stderr)
            sys.exit(1)
            i += 1

    # Default camera setup
    cam = Camera()

    cam.aspect_ratio = 16.0 / 9.0
    cam.image_width = 800
    cam.samples_per_pixel = 50  # Less samples for quicker rendering
    cam.max_depth = 50
    cam.vfov = 20.0
    cam.look_from = Point3(13.0, 2.0, 3.0)
    cam.look_at = Point3(0.0, 0.0, 0.0)
    cam.vup = Vec3(0.0, 1.0, 0.0)
    cam.defocus_angle = 0.6
    cam.focus_dist = 10.0

    # Setup world - either from file or randomly generated
    world = None
    if os.path.exists(filepath):
        world, file_cam = create_world_from_file(filepath)
        if file_cam is not None:
            cam = file_cam

    if world is None:
        print(
            f"File {filepath} not found or error loading. Generating random scene instead.",
            file=sys.stderr,
        )
        world = random_scene()

    # Determine the output file or stdout
    output_file = sys.stdout
    if output_path:
        try:
            output_file = open(output_path, 'w')
        except IOError as e:
            print(f"Error: Could not open output file {output_path}: {e}", file=sys.stderr)
            sys.exit(1)

    try:
        # Render the scene
        cam.render(world, output_file, num_threads)
    finally:
        # Close the output file if it's not stdout
        if output_file != sys.stdout:
            output_file.close()


if __name__ == "__main__":
    main()
