use std::io::Write;

use crate::color::{self, Color};
use crate::vec3::Vec3;

pub struct Image { pub width: usize, pub height: usize, pub pixels: Vec<Color> }

impl Image {
    pub fn new(width: usize, height: usize) -> Self { Self { width, height, pixels: vec![Vec3([0.0,0.0,0.0]); width*height] } }
    pub fn set_pixel(&mut self, x: usize, y: usize, color: Color) { self.pixels[y*self.width+x] = color; }
    pub fn write_ppm<W: Write>(&self, out: &mut W) -> std::io::Result<()> {
        writeln!(out, "P3\n{} {}\n255", self.width, self.height)?;
        for j in 0..self.height { for i in 0..self.width { color::write_color(out, self.pixels[j*self.width+i])?; } }
        Ok(())
    }
}


