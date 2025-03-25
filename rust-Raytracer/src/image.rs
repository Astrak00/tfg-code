use std::io::{self, Write};

use crate::{color::write_color, vec3::Color};

pub struct Image {
    width: usize,
    height: usize,
    pixels: Vec<Color>,
}

impl Image {
    pub fn new(width: usize, height: usize) -> Self {
        Self {
            width,
            height,
            pixels: vec![Color::new(0.0, 0.0, 0.0); width * height],
        }
    }

    pub fn set_pixel(&mut self, x: usize, y: usize, color: Color) {
        self.pixels[y * self.width + x] = color;
    }

    pub fn write_to<W: Write>(&self, out: &mut W) -> io::Result<()> {
        // Write PPM header
        writeln!(out, "P3\n{} {}\n255", self.width, self.height)?;

        // Write all pixels
        for j in 0..self.height {
            for i in 0..self.width {
                write_color(out, &self.pixels[j * self.width + i])?;
            }
        }

        Ok(())
    }
}
