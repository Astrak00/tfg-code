use std::io::Write;

use crate::vec3::Vec3;

pub type Color = Vec3;

fn linear_to_gamma(x: f64) -> f64 { if x > 0.0 { x.sqrt() } else { 0.0 } }

pub fn write_color<W: Write>(out: &mut W, pixel_color: Color) -> std::io::Result<()> {
    let mut r = pixel_color.0[0];
    let mut g = pixel_color.0[1];
    let mut b = pixel_color.0[2];

    r = linear_to_gamma(r);
    g = linear_to_gamma(g);
    b = linear_to_gamma(b);

    let clamp = |x: f64, min: f64, max: f64| if x < min { min } else if x > max { max } else { x };
    let intensity = (0.0, 0.999);
    let r_byte = (256.0 * clamp(r, intensity.0, intensity.1)) as i32;
    let g_byte = (256.0 * clamp(g, intensity.0, intensity.1)) as i32;
    let b_byte = (256.0 * clamp(b, intensity.0, intensity.1)) as i32;

    writeln!(out, "{} {} {}", r_byte, g_byte, b_byte)
}


