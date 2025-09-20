#ifndef IMAGE_HPP
#define IMAGE_HPP

#include "color.cuh"

#include <vector>

class Image {
  public:
    Image(int width, int height) : width(width), height(height) { pixels.resize(width * height); }

    color & pixel(int x, int y) { return pixels[y * width + x]; }

    void write_to_stream(std::ostream & out) const {
      // Output the PPM header
      out << "P3\n" << width << ' ' << height << "\n255\n";

      // Output all pixels
      for (int j = 0; j < height; j++) {
        for (int i = 0; i < width; i++) { write_color(out, pixels[j * width + i]); }
      }
    }

  private:
    int width;
    int height;
    std::vector<color> pixels;
};

#endif
