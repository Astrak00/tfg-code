pub mod camera;
pub mod color;
pub mod hittable;
pub mod image;
pub mod material;
pub mod ray;
pub mod utils;
pub mod vec3;

// Re-export commonly used items
pub use camera::Camera;
pub use hittable::{Hittable, HittableList, Sphere};
pub use material::{Dielectric, Lambertian, Material, Metal};
pub use ray::Ray;
pub use vec3::{Color, Point3, Vec3};
