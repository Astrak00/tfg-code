use std::io::Write;
use std::sync::atomic::{AtomicI32, Ordering};

use rayon::prelude::*;

use crate::hittable::{Hittable, HitRecord};
use crate::image::Image;
use crate::interval::Interval;
use crate::ray::Ray;
use crate::rtweekend::{degrees_to_radians, INFINITY};
use crate::vec3::{Point3, Vec3};
use crate::color::Color;

pub struct Camera {
    pub aspect_ratio: f64,
    pub image_width: usize,
    pub samples_per_pixel: usize,
    pub max_depth: i32,
    pub vfov: f64,
    pub look_from: Point3,
    pub look_at: Point3,
    pub vup: Vec3,
    pub defocus_angle: f64,
    pub focus_dist: f64,

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
        Self {
            aspect_ratio: 1.0,
            image_width: 100,
            samples_per_pixel: 10,
            max_depth: 10,
            vfov: 90.0,
            look_from: Vec3([0.0,0.0,0.0]),
            look_at: Vec3([0.0,0.0,-1.0]),
            vup: Vec3([0.0,1.0,0.0]),
            defocus_angle: 0.0,
            focus_dist: 10.0,
            image_height: 0,
            pixel_samples_scale: 0.0,
            center: Vec3([0.0,0.0,0.0]),
            pixel00_loc: Vec3([0.0,0.0,0.0]),
            pixel_delta_u: Vec3([0.0,0.0,0.0]),
            pixel_delta_v: Vec3([0.0,0.0,0.0]),
            u: Vec3([0.0,0.0,0.0]),
            v: Vec3([0.0,0.0,0.0]),
            w: Vec3([0.0,0.0,0.0]),
            defocus_disk_u: Vec3([0.0,0.0,0.0]),
            defocus_disk_v: Vec3([0.0,0.0,0.0]),
        }
    }
}

impl Camera {
    pub fn initialize(&mut self) {
        self.image_height = (self.image_width as f64 / self.aspect_ratio) as usize;
        if self.image_height < 1 { self.image_height = 1; }

        self.pixel_samples_scale = 1.0 / self.samples_per_pixel as f64;
        self.center = self.look_from;

        let theta = degrees_to_radians(self.vfov);
        let h = (theta / 2.0).tan();
        let viewport_height = 2.0 * h * self.focus_dist;
        let viewport_width = viewport_height * (self.image_width as f64 / self.image_height as f64);

        self.w = Vec3::unit(self.look_from - self.look_at);
        self.u = Vec3::unit(Vec3::cross(self.vup, self.w));
        self.v = Vec3::cross(self.w, self.u);

        let viewport_u = self.u * viewport_width;
        let viewport_v = self.v * -viewport_height;

        self.pixel_delta_u = viewport_u / self.image_width as f64;
        self.pixel_delta_v = viewport_v / self.image_height as f64;

        let viewport_upper_left = self.center - self.w * self.focus_dist - viewport_u/2.0 - viewport_v/2.0;
        self.pixel00_loc = viewport_upper_left + (self.pixel_delta_u + self.pixel_delta_v) * 0.5;

        let defocus_radius = self.focus_dist * (self.defocus_angle.to_radians() / 2.0).tan();
        self.defocus_disk_u = self.u * defocus_radius;
        self.defocus_disk_v = self.v * defocus_radius;
    }

    fn sample_square(&self) -> Vec3 {
        Vec3([rand::random::<f64>() - 0.5, rand::random::<f64>() - 0.5, 0.0])
    }

    fn random_in_unit_disk() -> Vec3 {
        loop {
            let p = Vec3([2.0*rand::random::<f64>()-1.0, 2.0*rand::random::<f64>()-1.0, 0.0]);
            if p.length_squared() < 1.0 { return p; }
        }
    }

    fn defocus_disk_sample(&self) -> Point3 {
        let p = Self::random_in_unit_disk();
        self.center + self.defocus_disk_u * p.0[0] + self.defocus_disk_v * p.0[1]
    }

    pub fn get_ray(&self, i: usize, j: usize) -> Ray {
        let offset = self.sample_square();
        let pixel_sample = self.pixel00_loc + self.pixel_delta_u * (i as f64 + offset.x()) + self.pixel_delta_v * (j as f64 + offset.y());
        let ray_origin = if self.defocus_angle > 0.0 { self.defocus_disk_sample() } else { self.center };
        let ray_direction = pixel_sample - ray_origin;
        Ray { orig: ray_origin, dir: ray_direction }
    }

    fn ray_color<H: Hittable>(&self, r: &Ray, depth: i32, world: &H) -> Color {
        if depth <= 0 { return Vec3([0.0,0.0,0.0]); }
        let mut rec = HitRecord::new();
        if world.hit(r, Interval { min: 0.001, max: INFINITY }, &mut rec) {
            if let Some(mat) = rec.mat { if let Some((attenuation, scattered)) = mat.scatter(r, &rec) { return attenuation * self.ray_color(&scattered, depth-1, world); } }
            return Vec3([0.0,0.0,0.0]);
        }
        let unit_direction = Vec3::unit(r.direction());
        let a = 0.5 * (unit_direction.y() + 1.0);
        let white = Vec3([1.0,1.0,1.0]);
        let blue = Vec3([0.5,0.7,1.0]);
        white * (1.0 - a) + blue * a
    }

    pub fn render<H: Hittable, W: Write>(&mut self, world: &H, out: &mut W, num_threads: usize) -> std::io::Result<()> {
        self.initialize();
        let mut img = Image::new(self.image_width, self.image_height);

        if num_threads <= 1 {
            for j in 0..self.image_height {
                eprint!("\rScanlines remaining: {} ", self.image_height - j);
                for i in 0..self.image_width {
                    let mut pixel_color = Vec3([0.0,0.0,0.0]);
                    for _ in 0..self.samples_per_pixel {
                        let r = self.get_ray(i, j);
                        pixel_color += self.ray_color(&r, self.max_depth, world);
                    }
                    pixel_color *= self.pixel_samples_scale;
                    img.set_pixel(i, j, pixel_color);
                }
            }
        } else {
            rayon::ThreadPoolBuilder::new().num_threads(num_threads).build_global().ok();
            let lines_remaining = AtomicI32::new(self.image_height as i32);
            let pixels: Vec<Color> = (0..self.image_width*self.image_height).into_par_iter().map(|pixel_idx| {
                let i = pixel_idx % self.image_width;
                let j = pixel_idx / self.image_width;
                let mut pixel_color = Vec3([0.0,0.0,0.0]);
                for _ in 0..self.samples_per_pixel {
                    let r = self.get_ray(i, j);
                    pixel_color += self.ray_color(&r, self.max_depth, world);
                }
                if i == 0 { let rem = lines_remaining.fetch_sub(1, Ordering::SeqCst) - 1; eprint!("\rScanlines remaining: {} ", rem); }
                pixel_color * self.pixel_samples_scale
            }).collect();
            for pixel_idx in 0..self.image_width*self.image_height {
                let i = pixel_idx % self.image_width;
                let j = pixel_idx / self.image_width;
                img.set_pixel(i, j, pixels[pixel_idx]);
            }
        }
        eprint!("\rScanlines remaining: 0 ");
        img.write_ppm(out)?;
        eprintln!("\rDone.                 ");
        Ok(())
    }
}


