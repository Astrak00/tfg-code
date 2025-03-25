use std::io::{self, Write};

use crate::vec3::Color;

// Convert linear to gamma (gamma 2)
pub fn linear_to_gamma(linear_component: f64) -> f64 {
    if linear_component > 0.0 {
        linear_component.sqrt()
    } else {
        0.0
    }
}

pub fn clamp(x: f64, min: f64, max: f64) -> f64 {
    if x < min {
        min
    } else if x > max {
        max
    } else {
        x
    }
}

pub fn write_color<W: Write>(out: &mut W, pixel_color: &Color) -> io::Result<()> {
    // Get components
    let r = pixel_color.x();
    let g = pixel_color.y();
    let b = pixel_color.z();

    // Apply gamma correction
    let r = linear_to_gamma(r);
    let g = linear_to_gamma(g);
    let b = linear_to_gamma(b);

    // Translate to [0,255] range
    let intensity_min = 0.000;
    let intensity_max = 0.999;
    let r_byte = (256.0 * clamp(r, intensity_min, intensity_max)) as u8;
    let g_byte = (256.0 * clamp(g, intensity_min, intensity_max)) as u8;
    let b_byte = (256.0 * clamp(b, intensity_min, intensity_max)) as u8;

    // Write the bytes
    writeln!(out, "{} {} {}", r_byte, g_byte, b_byte)
}
