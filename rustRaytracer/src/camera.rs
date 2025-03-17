use std::{
    io::{self, Write},
    sync::{Arc, Mutex},
};

use rayon::prelude::*;

use crate::{
    hittable::{HitRecord, Hittable},
    image::Image,
    ray::Ray,
    utils::{degrees_to_radians, random_double, Interval, INFINITY},
    vec3::{cross, random_in_unit_disk, unit_vector, Color, Point3, Vec3},
};

pub struct Camera {
    // Public fields
    pub aspect_ratio: f64,
    pub image_width: usize,
    pub samples_per_pixel: usize,
    pub max_depth: usize,
    pub vfov: f64,
    pub look_from: Point3,
    pub look_at: Point3,
    pub vup: Vec3,
    pub defocus_angle: f64,
    pub focus_dist: f64,

    // Private fields
    image_height: usize,
    pixel_samples_scale: f64,
    center: Point3,
    pixel00_loc: Point3,
    pixel_delta_u: Vec3,
    pixel_delta_v: Vec3,
    u: Vec3,
    v: Vec3,
    w: Vec3,
    defocus_disk_u: Vec3,
    defocus_disk_v: Vec3,
}

impl Default for Camera {
    fn default() -> Self {
        Self::new()
    }
}

impl Camera {
    pub fn new() -> Self {
        Self {
            aspect_ratio: 1.0,
            image_width: 100,
            samples_per_pixel: 10,
            max_depth: 10,
            vfov: 90.0,
            look_from: Point3::new(0.0, 0.0, 0.0),
            look_at: Point3::new(0.0, 0.0, -1.0),
            vup: Vec3::new(0.0, 1.0, 0.0),
            defocus_angle: 0.0,
            focus_dist: 10.0,
            
            // These will be initialized later
            image_height: 0,
            pixel_samples_scale: 0.0,
            center: Vec3::new(0.0, 0.0, 0.0),
            pixel00_loc: Vec3::new(0.0, 0.0, 0.0),
            pixel_delta_u: Vec3::new(0.0, 0.0, 0.0),
            pixel_delta_v: Vec3::new(0.0, 0.0, 0.0),
            u: Vec3::new(0.0, 0.0, 0.0),
            v: Vec3::new(0.0, 0.0, 0.0),
            w: Vec3::new(0.0, 0.0, 0.0),
            defocus_disk_u: Vec3::new(0.0, 0.0, 0.0),
            defocus_disk_v: Vec3::new(0.0, 0.0, 0.0),
        }
    }

    

    pub fn initialize(&mut self) {
        // Calculate image height
        self.image_height = (self.image_width as f64 / self.aspect_ratio) as usize;
        if self.image_height < 1 {
            self.image_height = 1;
        }

        self.pixel_samples_scale = 1.0 / self.samples_per_pixel as f64;
        self.center = self.look_from;

        // Determine viewport dimensions
        let theta = degrees_to_radians(self.vfov);
        let h = (theta / 2.0).tan();
        let viewport_height = 2.0 * h * self.focus_dist;
        let viewport_width = viewport_height * (self.image_width as f64 / self.image_height as f64);

        // Calculate the u,v,w unit basis vectors for the camera coordinate frame
        self.w = unit_vector(&(self.look_from - self.look_at));
        self.u = unit_vector(&cross(&self.vup, &self.w));
        self.v = cross(&self.w, &self.u);

        // Calculate vectors across the horizontal and down the vertical viewport edges
        let viewport_u = self.u * viewport_width;
        let viewport_v = self.v * -viewport_height;

        // Calculate horizontal and vertical delta vectors from pixel to pixel
        self.pixel_delta_u = viewport_u / self.image_width as f64;
        self.pixel_delta_v = viewport_v / self.image_height as f64;

        // Calculate the location of the upper left pixel
        let viewport_upper_left = self.center - self.w * self.focus_dist
            - viewport_u / 2.0 - viewport_v / 2.0;
        self.pixel00_loc = viewport_upper_left + (self.pixel_delta_u + self.pixel_delta_v) * 0.5;

        // Calculate the camera defocus disk basis vectors
        let defocus_radius = self.focus_dist * degrees_to_radians(self.defocus_angle / 2.0).tan();
        self.defocus_disk_u = self.u * defocus_radius;
        self.defocus_disk_v = self.v * defocus_radius;
    }

    fn get_ray(&self, i: usize, j: usize) -> Ray {
        // Get a randomly sampled camera ray for the pixel at location i,j
        let offset = self.sample_square();
        let pixel_sample = self.pixel00_loc
            + self.pixel_delta_u * (i as f64 + offset.x())
            + self.pixel_delta_v * (j as f64 + offset.y());

        let ray_origin = if self.defocus_angle <= 0.0 {
            self.center
        } else {
            self.defocus_disk_sample()
        };
        
        let ray_direction = pixel_sample - ray_origin;

        Ray::new(ray_origin, ray_direction)
    }

    pub fn render<W: Write>(&mut self, world: &dyn Hittable, out: &mut W, num_threads: usize) -> io::Result<()> {
        self.initialize();

        // Create image data
        let mut img = Image::new(self.image_width, self.image_height);

        if num_threads <= 1 {
            let mut processed_lines = 0;
            for j in 0..self.image_height {
                write!(out, "\rScanlines remaining: {} ", self.image_height - processed_lines)?;
                out.flush()?;

                for i in 0..self.image_width {
                    let mut pixel_color = Color::new(0.0, 0.0, 0.0);
                    for _ in 0..self.samples_per_pixel {
                        let r = self.get_ray(i, j);
                        pixel_color = pixel_color + self.ray_color(&r, self.max_depth, world);
                    }
                    img.set_pixel(i, j, pixel_color * self.pixel_samples_scale);
                }
                processed_lines += 1;
            }
        } else {
            // Use Rayon for parallel processing
            let processed_lines = Arc::new(Mutex::new(0));
            
            // Create a thread-safe container to store all pixel colors
            let all_pixels: Arc<Mutex<Vec<Color>>> = Arc::new(Mutex::new(
                vec![Color::new(0.0, 0.0, 0.0); self.image_width * self.image_height]
            ));
            
            // Create a vector of row indices
            let rows: Vec<usize> = (0..self.image_height).collect();
            
            // Process rows in parallel
            rows.par_iter().for_each(|&j| {
                let mut row_pixels = vec![Color::new(0.0, 0.0, 0.0); self.image_width];
                
                for i in 0..self.image_width {
                    let mut pixel_color = Color::new(0.0, 0.0, 0.0);
                    for _ in 0..self.samples_per_pixel {
                        let r = self.get_ray(i, j);
                        pixel_color = pixel_color + self.ray_color(&r, self.max_depth, world);
                    }
                    row_pixels[i] = pixel_color * self.pixel_samples_scale;
                }
                
                // Store the pixel colors in the shared container
                let mut pixels = all_pixels.lock().unwrap();
                for i in 0..self.image_width {
                    pixels[j * self.image_width + i] = row_pixels[i];
                }
                
                // Update progress
                let mut count = processed_lines.lock().unwrap();
                *count += 1;
                // We don't print here to avoid contention, just count
            });
            
            // After parallel processing, update the image with all the calculated colors
            let pixels = all_pixels.lock().unwrap();
            for j in 0..self.image_height {
                for i in 0..self.image_width {
                    img.set_pixel(i, j, pixels[j * self.image_width + i]);
                }
            }
        }

        write!(out, "\rScanlines remaining: 0 ")?;

        // Write the image to standard output
        let mut stdout = std::io::stdout();
        img.write_to(&mut stdout)?;

        writeln!(out, "\rDone.                 ")?;
        Ok(())
    }

    fn sample_square(&self) -> Vec3 {
        // Returns a random point in the [-0.5,0.5] x [-0.5,0.5] square
        Vec3::new(random_double() - 0.5, random_double() - 0.5, 0.0)
    }

    fn defocus_disk_sample(&self) -> Point3 {
        // Returns a random point in the camera defocus disk
        let p = random_in_unit_disk();
        self.center + self.defocus_disk_u * p.x() + self.defocus_disk_v * p.y()
    }

    fn ray_color(&self, r: &Ray, depth: usize, world: &dyn Hittable) -> Color {
        // If we've exceeded the ray bounce limit, no more light is gathered
        if depth == 0 {
            return Color::new(0.0, 0.0, 0.0);
        }

        let mut rec = HitRecord {
            p: Point3::new(0.0, 0.0, 0.0),
            normal: Vec3::new(0.0, 0.0, 0.0),
            mat: Arc::new(Lambertian::new(Color::new(0.0, 0.0, 0.0))),
            t: 0.0,
            front_face: false,
        };

        if world.hit(r, Interval::new(0.001, INFINITY), &mut rec) {
            let (scatter_happened, attenuation, scattered) = rec.mat.scatter(r, &rec);
            if scatter_happened {
                return attenuation * self.ray_color(&scattered, depth - 1, world);
            }
            return Color::new(0.0, 0.0, 0.0);
        }

        // Background - a simple gradient
        let unit_direction = unit_vector(&r.direction());
        let a = 0.5 * (unit_direction.y() + 1.0);
        Color::new(1.0, 1.0, 1.0) * (1.0 - a) + Color::new(0.5, 0.7, 1.0) * a
    }
}

use crate::{material::Lambertian};
