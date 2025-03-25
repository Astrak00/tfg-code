from vec3 import Color
from color import write_color


class Image:
    def __init__(self, width, height):
        self.width = width
        self.height = height
        self.pixels = [Color(0.0, 0.0, 0.0) for _ in range(width * height)]

    def set_pixel(self, x, y, color):
        self.pixels[y * self.width + x] = color

    def write_to(self, out):
        """Write the image to the given file stream in PPM format"""
        # Write PPM header
        out.write(f"P3\n{self.width} {self.height}\n255\n")

        # Write all pixels
        for j in range(self.height):
            for i in range(self.width):
                write_color(out, self.pixels[j * self.width + i])

        return True
