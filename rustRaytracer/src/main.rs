mod camera;
mod color;
mod hittable;
mod image;
mod material;
mod ray;
mod utils;
mod vec3;

use std::{
    io::{self},
    sync::Arc,
};

use camera::Camera;
use hittable::{HittableList, Sphere};
use material::{Dielectric, Lambertian, Metal};
use utils::random_double;
use vec3::{Color, Point3, Vec3};

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

    world
}

fn main() -> io::Result<()> {
    // Setup world
    let world = random_scene();

    // Camera
    let mut cam = Camera::new();
    cam.aspect_ratio = 16.0 / 9.0;
    cam.image_width = 1400;
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
