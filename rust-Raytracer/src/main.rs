use std::env;
use std::fs::File;
use std::io::{BufRead, BufReader, Write};

use ray_tracer::camera::Camera;
use ray_tracer::color::Color;
use ray_tracer::hittable::Hittable;
use ray_tracer::hittable_list::HittableList;
use ray_tracer::interval::Interval;
use ray_tracer::material::{Dielectric, Lambertian, Material, Metal};
use ray_tracer::rtweekend::{INFINITY};
use ray_tracer::sphere::Sphere;
use ray_tracer::vec3::{Point3, Vec3};

fn check_camera_parameters(cam: &mut Camera, line: &str) {
    let parts: Vec<&str> = line.split_whitespace().collect();
    match parts.get(1).copied() {
        Some("ratio") => {
            if parts.len() >= 4 {
                if let (Ok(a), Ok(b)) = (parts[2].parse::<f64>(), parts[3].parse::<f64>()) { cam.aspect_ratio = a/b; }
            }
        }
        Some("width") => { if let Some(v) = parts.get(2) { if let Ok(w) = v.parse::<usize>() { cam.image_width = w; } } }
        Some("samplesPerPixel") => { if let Some(v) = parts.get(2) { if let Ok(s) = v.parse::<usize>() { cam.samples_per_pixel = s; } } }
        Some("maxDepth") => { if let Some(v) = parts.get(2) { if let Ok(d) = v.parse::<i32>() { cam.max_depth = d; } } }
        Some("vfov") => { if let Some(v) = parts.get(2) { if let Ok(f) = v.parse::<f64>() { cam.vfov = f; } } }
        Some("lookFrom") => { if parts.len() >= 5 { if let (Ok(x),Ok(y),Ok(z))=(parts[2].parse(),parts[3].parse(),parts[4].parse()) { cam.look_from = Vec3([x,y,z]); } } }
        Some("lookAt") => { if parts.len() >= 5 { if let (Ok(x),Ok(y),Ok(z))=(parts[2].parse(),parts[3].parse(),parts[4].parse()) { cam.look_at = Vec3([x,y,z]); } } }
        Some("vup") => { if parts.len() >= 5 { if let (Ok(x),Ok(y),Ok(z))=(parts[2].parse(),parts[3].parse(),parts[4].parse()) { cam.vup = Vec3([x,y,z]); } } }
        Some("defocusAngle") => { if let Some(v) = parts.get(2) { if let Ok(a) = v.parse::<f64>() { cam.defocus_angle = a; } } }
        Some("focusDist") => { if let Some(v) = parts.get(2) { if let Ok(d) = v.parse::<f64>() { cam.focus_dist = d; } } }
        _ => {}
    }
}

fn create_world_from_file(path: &str) -> (HittableList, Camera) {
    let mut world: HittableList = HittableList { objects: vec![] };
    let mut cam: Camera = Camera::default();

    // Add ground sphere
    let ground = Lambertian { albedo: Vec3([0.5,0.5,0.5]) };
    world.add(Box::new(Sphere::new(Vec3([0.0, -1000.0, 0.0]), 1000.0, ground)));

    if let Ok(file) = File::open(path) {
        let reader = BufReader::new(file);
        for line in reader.lines() {
            let line = line.unwrap();
            if line.trim().is_empty() || line.trim_start().starts_with('#') { continue; }
            if line.starts_with('c') { check_camera_parameters(&mut cam, &line); continue; }
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() < 5 { continue; }
            let (x, y, z, radius) = match (parts[0].parse::<f64>(), parts[1].parse::<f64>(), parts[2].parse::<f64>(), parts[3].parse::<f64>()) {
                (Ok(x), Ok(y), Ok(z), Ok(r)) => (x, y, z, r),
                _ => continue,
            };
            let center = Vec3([x,y,z]);
            match parts[4] {
                "lambertian" => {
                    if parts.len() >= 8 { if let (Ok(r),Ok(g),Ok(b))=(parts[5].parse(),parts[6].parse(),parts[7].parse()) { let mat = Lambertian { albedo: Vec3([r,g,b]) }; world.add(Box::new(Sphere::new(center, radius, mat))); } }
                }
                "metal" => {
                    if parts.len() >= 9 { if let (Ok(r),Ok(g),Ok(b),Ok(f))=(parts[5].parse(),parts[6].parse(),parts[7].parse(),parts[8].parse()) { let mat = Metal { albedo: Vec3([r,g,b]), fuzz: f }; world.add(Box::new(Sphere::new(center, radius, mat))); } }
                }
                "dielectric" => {
                    if parts.len() >= 6 { if let Ok(ir) = parts[5].parse::<f64>() { let mat = Dielectric { refraction_index: ir }; world.add(Box::new(Sphere::new(center, radius, mat))); } }
                }
                _ => {}
            }
        }
    }
    (world, cam)
}

fn random_scene() -> HittableList {
    use rand::Rng;
    let mut rng = rand::thread_rng();
    let mut world: HittableList = HittableList { objects: vec![] };
    let ground = Lambertian { albedo: Vec3([0.5,0.5,0.5]) }; world.add(Box::new(Sphere::new(Vec3([0.0,-1000.0,0.0]), 1000.0, ground)));
    for a in -11..11 { for b in -11..11 { let choose_mat: f64 = rng.gen(); let center = Vec3([a as f64 + 0.9*rng.gen::<f64>(), 0.2, b as f64 + 0.9*rng.gen::<f64>()]); if (center - Vec3([4.0,0.2,0.0])).length() > 0.9 { if choose_mat < 0.8 { let albedo = Vec3([rng.gen(), rng.gen(), rng.gen()]) * Vec3([rng.gen(), rng.gen(), rng.gen()]); let mat = Lambertian { albedo }; world.add(Box::new(Sphere::new(center, 0.2, mat))); } else if choose_mat < 0.95 { let albedo = Vec3([rng.gen_range(0.1..1.0), rng.gen_range(0.1..1.0), rng.gen_range(0.1..1.0)]); let fuzz = rng.gen::<f64>() * 0.5; let mat = Metal { albedo, fuzz }; world.add(Box::new(Sphere::new(center, 0.2, mat))); } else { let mat = Dielectric { refraction_index: 1.5 }; world.add(Box::new(Sphere::new(center, 0.2, mat))); } } } }
    let material1 = Dielectric { refraction_index: 1.5 }; world.add(Box::new(Sphere::new(Vec3([0.0,1.0,0.0]), 1.0, material1)));
    let material2 = Lambertian { albedo: Vec3([0.4,0.2,0.1]) }; world.add(Box::new(Sphere::new(Vec3([-4.0,1.0,0.0]), 1.0, material2)));
    let material3 = Metal { albedo: Vec3([0.7,0.6,0.5]), fuzz: 0.0 }; world.add(Box::new(Sphere::new(Vec3([4.0,1.0,0.0]), 1.0, material3)));
    world
}

fn main() {
    // Defaults
    let mut filepath = String::from("sphere_data.txt");
    let mut output_path: Option<String> = None;
    let mut num_threads: usize = 0;

    // Simple CLI parse: --path <file> --output <file> --cores <n>
    let mut args = env::args().skip(1).collect::<Vec<_>>();
    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--path" => { if i+1 < args.len() { filepath = args[i+1].clone(); i+=1; } }
            "--output" => { if i+1 < args.len() { output_path = Some(args[i+1].clone()); i+=1; } }
            "--cores" => { if i+1 < args.len() { if let Ok(n) = args[i+1].parse::<usize>() { num_threads = n; } i+=1; } }
            _ => {}
        }
        i+=1;
    }

    let (world, mut cam) = create_world_from_file(&filepath);
    let world = if world.objects.is_empty() { random_scene() } else { world };

    if cam.image_width == 0 { cam.image_width = 1200; }
    if cam.aspect_ratio == 0.0 { cam.aspect_ratio = 16.0/9.0; }
    if cam.samples_per_pixel == 0 { cam.samples_per_pixel = 50; }
    if cam.max_depth == 0 { cam.max_depth = 50; }
    if cam.vfov == 0.0 { cam.vfov = 20.0; }
    if cam.focus_dist == 0.0 { cam.focus_dist = 10.0; }

    let mut output: Box<dyn Write> = if let Some(path) = output_path { Box::new(File::create(path).expect("Could not create output file")) } else { Box::new(std::io::stdout()) };
    if num_threads == 0 { num_threads = num_cpus::get(); }
    eprintln!("Cores: {}", num_threads);
    cam.render(&world, &mut output, num_threads).expect("Render failed");
}


