use rand::Rng;

pub const INFINITY: f64 = f64::MAX;
pub const PI: f64 = std::f64::consts::PI;

pub fn degrees_to_radians(degrees: f64) -> f64 { degrees * PI / 180.0 }

pub fn random_double() -> f64 { rand::thread_rng().gen::<f64>() }
pub fn random_double_range(min: f64, max: f64) -> f64 { min + (max - min) * random_double() }


