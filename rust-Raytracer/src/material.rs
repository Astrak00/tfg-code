use rand::Rng;

use crate::ray::Ray;
use crate::vec3::{Vec3, Point3};
use crate::hittable::HitRecord;

pub trait Material: Sync + Send {
    fn scatter(&self, r_in: &Ray, rec: &HitRecord) -> Option<(Vec3, Ray)>;
}

fn reflect(v: Vec3, n: Vec3) -> Vec3 { v - n * (2.0 * Vec3::dot(v, n)) }

fn refract(uv: Vec3, n: Vec3, etai_over_etat: f64) -> Vec3 {
    let cos_theta = Vec3::dot(-uv, n).min(1.0);
    let r_out_perp = (uv + n * cos_theta) * etai_over_etat;
    let r_out_parallel = n * (-(1.0 - r_out_perp.length_squared()).abs().sqrt());
    r_out_perp + r_out_parallel
}

fn random_unit_vector() -> Vec3 {
    loop {
        let p = Vec3::new(rand::thread_rng().gen_range(-1.0..1.0), rand::thread_rng().gen_range(-1.0..1.0), rand::thread_rng().gen_range(-1.0..1.0));
        let lensq = p.length_squared();
        if 1e-160 < lensq && lensq <= 1.0 { return p / lensq.sqrt(); }
    }
}

pub struct Lambertian { pub albedo: Vec3 }
impl Material for Lambertian {
    fn scatter(&self, _r_in: &Ray, rec: &HitRecord) -> Option<(Vec3, Ray)> {
        let mut scatter_direction = rec.normal + random_unit_vector();
        if scatter_direction.near_zero() { scatter_direction = rec.normal; }
        Some((self.albedo, Ray::new(rec.p, scatter_direction)))
    }
}

pub struct Metal { pub albedo: Vec3, pub fuzz: f64 }
impl Material for Metal {
    fn scatter(&self, r_in: &Ray, rec: &HitRecord) -> Option<(Vec3, Ray)> {
        let mut reflected = reflect(Vec3::unit(r_in.direction()), rec.normal);
        let fuzz = self.fuzz.min(1.0);
        let rand_dir = random_unit_vector() * fuzz;
        reflected = reflected + rand_dir;
        let scattered = Ray::new(rec.p, reflected);
        if Vec3::dot(scattered.direction(), rec.normal) > 0.0 {
            Some((self.albedo, scattered))
        } else { None }
    }
}

pub struct Dielectric { pub refraction_index: f64 }
impl Dielectric {
    fn reflectance(cosine: f64, ref_idx: f64) -> f64 {
        let mut r0 = (1.0 - ref_idx) / (1.0 + ref_idx);
        r0 = r0 * r0;
        r0 + (1.0 - r0) * (1.0 - cosine).powi(5)
    }
}
impl Material for Dielectric {
    fn scatter(&self, r_in: &Ray, rec: &HitRecord) -> Option<(Vec3, Ray)> {
        let attenuation = Vec3::new(1.0, 1.0, 1.0);
        let refraction_ratio = if rec.front_face { 1.0 / self.refraction_index } else { self.refraction_index };
        let unit_direction = Vec3::unit(r_in.direction());
        let cos_theta = Vec3::dot(-unit_direction, rec.normal).min(1.0);
        let sin_theta = (1.0 - cos_theta*cos_theta).sqrt();
        let cannot_refract = refraction_ratio * sin_theta > 1.0;
        let direction = if cannot_refract || Self::reflectance(cos_theta, refraction_ratio) > rand::random::<f64>() {
            reflect(unit_direction, rec.normal)
        } else { refract(unit_direction, rec.normal, refraction_ratio) };
        Some((attenuation, Ray::new(rec.p, direction)))
    }
}


