mod camera;
mod color;
mod hittable;
mod image;
mod material;
mod ray;
mod utils;
mod vec3;

use std::{
    env,
    fs::File,
    io::{self, BufRead, BufReader},
    path::Path,
    sync::Arc,
};

use camera::Camera;
use hittable::{HittableList, Sphere};
use material::{Dielectric, Lambertian, Metal};
use utils::random_double;
use vec3::{Color, Point3, Vec3};

fn create_world_from_file(filepath: &str) -> io::Result<HittableList> {
    let mut world = HittableList::new();

    // Add ground sphere
    let ground_material = Arc::new(Lambertian::new(Color::new(0.5, 0.5, 0.5)));
    world.add(Arc::new(Sphere::new(
        Point3::new(0.0, -1000.0, 0.0),
        1000.0,
        ground_material,
    )));

    // Read spheres from file
    let file = File::open(filepath)?;
    let reader = BufReader::new(file);

    for line in reader.lines() {
        let line = line?;
        // Skip empty lines and comments
        if line.is_empty() || line.trim().starts_with('#') {
            continue;
        }

        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() < 5 {
            continue; // Need at least x, y, z, radius, material_type
        }

        // Parse coordinates and radius
        let x = parts[0].parse::<f64>().unwrap_or(0.0);
        let y = parts[1].parse::<f64>().unwrap_or(0.0);
        let z = parts[2].parse::<f64>().unwrap_or(0.0);
        let radius = parts[3].parse::<f64>().unwrap_or(0.2);
        let material_type = parts[4];

        let center = Point3::new(x, y, z);

        // Parse material based on type
        match material_type {
            "lambertian" if parts.len() >= 8 => {
                let r = parts[5].parse::<f64>().unwrap_or(0.5);
                let g = parts[6].parse::<f64>().unwrap_or(0.5);
                let b = parts[7].parse::<f64>().unwrap_or(0.5);
                let material = Arc::new(Lambertian::new(Color::new(r, g, b)));
                world.add(Arc::new(Sphere::new(center, radius, material)));
            }
            "metal" if parts.len() >= 9 => {
                let r = parts[5].parse::<f64>().unwrap_or(0.5);
                let g = parts[6].parse::<f64>().unwrap_or(0.5);
                let b = parts[7].parse::<f64>().unwrap_or(0.5);
                let fuzz = parts[8].parse::<f64>().unwrap_or(0.0);
                let material = Arc::new(Metal::new(Color::new(r, g, b), fuzz));
                world.add(Arc::new(Sphere::new(center, radius, material)));
            }
            "dielectric" if parts.len() >= 6 => {
                let index = parts[5].parse::<f64>().unwrap_or(1.5);
                let material = Arc::new(Dielectric::new(index));
                world.add(Arc::new(Sphere::new(center, radius, material)));
            }
            _ => continue, // Skip invalid material types or insufficient parameters
        }
    }

    eprintln!("Loaded world from {}", filepath);
    Ok(world)
}

fn random_scene() -> HittableList {
    let mut world = HittableList::new();

    // Ground
    let ground_material = Arc::new(Lambertian::new(Color::new(0.5, 0.5, 0.5)));
    world.add(Arc::new(Sphere::new(
        Point3::new(0.0, -1000.0, 0.0),
        1000.0,
        ground_material,
    )));

    // Small random spheres
    for a in -11..11 {
        for b in -11..11 {
            let choose_mat = random_double();
            let center = Point3::new(
                a as f64 + 0.9 * random_double(),
                0.2,
                b as f64 + 0.9 * random_double(),
            );

            if (center - Point3::new(4.0, 0.2, 0.0)).length() > 0.9 {
                if choose_mat < 0.8 {
                    // Diffuse
                    let albedo = Color::new(
                        random_double() * random_double(),
                        random_double() * random_double(),
                        random_double() * random_double(),
                    );
                    let sphere_material = Arc::new(Lambertian::new(albedo));
                    world.add(Arc::new(Sphere::new(center, 0.2, sphere_material)));
                } else if choose_mat < 0.95 {
                    // Metal
                    let albedo = Color::new(
                        0.5 * (1.0 + random_double()),
                        0.5 * (1.0 + random_double()),
                        0.5 * (1.0 + random_double()),
                    );
                    let fuzz = 0.5 * random_double();
                    let sphere_material = Arc::new(Metal::new(albedo, fuzz));
                    world.add(Arc::new(Sphere::new(center, 0.2, sphere_material)));
                } else {
                    // Glass
                    let sphere_material = Arc::new(Dielectric::new(1.5));
                    world.add(Arc::new(Sphere::new(center, 0.2, sphere_material)));
                }
            }
        }
    }

    // Three larger spheres
    let material1 = Arc::new(Dielectric::new(1.5));
    world.add(Arc::new(Sphere::new(
        Point3::new(0.0, 1.0, 0.0),
        1.0,
        material1,
    )));

    let material2 = Arc::new(Lambertian::new(Color::new(0.4, 0.2, 0.1)));
    world.add(Arc::new(Sphere::new(
        Point3::new(-4.0, 1.0, 0.0),
        1.0,
        material2,
    )));

    let material3 = Arc::new(Metal::new(Color::new(0.7, 0.6, 0.5), 0.0));
    world.add(Arc::new(Sphere::new(
        Point3::new(4.0, 1.0, 0.0),
        1.0,
        material3,
    )));

    // After creating the random scene, also save it to a file
    if let Ok(mut file) = File::create("sphere_data.txt") {
        use std::io::Write;

        // Write all the spheres to the file
        // Small spheres
        for a in -11..11 {
            for b in -11..11 {
                let choose_mat = random_double();
                let center = Point3::new(
                    a as f64 + 0.9 * random_double(),
                    0.2,
                    b as f64 + 0.9 * random_double(),
                );

                if (center - Point3::new(4.0, 0.2, 0.0)).length() > 0.9 {
                    if choose_mat < 0.8 {
                        // Diffuse
                        let albedo = Color::new(
                            random_double() * random_double(),
                            random_double() * random_double(),
                            random_double() * random_double(),
                        );
                        writeln!(
                            file,
                            "{} {} {} {} lambertian {} {} {}",
                            center.x(),
                            center.y(),
                            center.z(),
                            0.2,
                            albedo.x(),
                            albedo.y(),
                            albedo.z()
                        )
                        .ok();
                    } else if choose_mat < 0.95 {
                        // Metal
                        let albedo = Color::new(
                            0.5 * (1.0 + random_double()),
                            0.5 * (1.0 + random_double()),
                            0.5 * (1.0 + random_double()),
                        );
                        let fuzz = 0.5 * random_double();
                        writeln!(
                            file,
                            "{} {} {} {} metal {} {} {} {}",
                            center.x(),
                            center.y(),
                            center.z(),
                            0.2,
                            albedo.x(),
                            albedo.y(),
                            albedo.z(),
                            fuzz
                        )
                        .ok();
                    } else {
                        // Glass
                        writeln!(
                            file,
                            "{} {} {} {} dielectric {}",
                            center.x(),
                            center.y(),
                            center.z(),
                            0.2,
                            1.5
                        )
                        .ok();
                    }
                }
            }
        }

        // Large spheres
        writeln!(file, "0.0 1.0 0.0 1.0 dielectric 1.5").ok();
        writeln!(file, "-4.0 1.0 0.0 1.0 lambertian 0.4 0.2 0.1").ok();
        writeln!(file, "4.0 1.0 0.0 1.0 metal 0.7 0.6 0.5 0.0").ok();
    }

    world
}

fn main() -> io::Result<()> {
    // Parse command line arguments
    let args: Vec<String> = env::args().collect();
    let default_path = "sphere_data.txt".to_string();

    let filepath = args
        .iter()
        .position(|arg| arg == "--path")
        .and_then(|pos| args.get(pos + 1).cloned())
        .unwrap_or(default_path);

    // Setup world - either from file or randomly generated
    let world = if Path::new(&filepath).exists() {
        match create_world_from_file(&filepath) {
            Ok(w) => w,
            Err(e) => {
                eprintln!("Error reading from {}: {}", filepath, e);
                eprintln!("Generating random scene instead.");
                random_scene()
            }
        }
    } else {
        eprintln!(
            "File {} not found. Generating random scene instead.",
            filepath
        );
        random_scene()
    };

    // Camera
    let mut cam = Camera::new();
    cam.aspect_ratio = 16.0 / 9.0;
    cam.image_width = 800;
    cam.samples_per_pixel = 50; // Less samples for quicker rendering
    cam.max_depth = 50;
    cam.vfov = 20.0;

    // Camera position and orientation
    cam.look_from = Point3::new(13.0, 2.0, 3.0);
    cam.look_at = Point3::new(0.0, 0.0, 0.0);
    cam.vup = Vec3::new(0.0, 1.0, 0.0);

    // Defocus blur
    cam.defocus_angle = 0.6;
    cam.focus_dist = 10.0;

    // Render the scene
    let stderr = io::stderr();
    let mut err_lock = stderr.lock();

    // Use multiple threads for rendering
    let num_threads = std::env::var("OMP_NUM_THREADS")
        .ok()
        .and_then(|val| val.parse::<usize>().ok())
        .unwrap_or_else(num_cpus::get);
    // println!("Rendering with {} threads", num_threads);

    cam.render(&world, &mut err_lock, num_threads)?;

    Ok(())
}
