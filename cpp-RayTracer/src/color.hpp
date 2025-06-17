#ifndef COLOR_HPP
#define COLOR_HPP

#include "interval.hpp"
#include "vec3.hpp"

using color = vec3;

inline double linear_to_gamma(double linear_component) {
  if (linear_component > 0) { return std::sqrt(linear_component); }

  return 0;
}

void write_color(std::ostream & out, color const & pixel_color) {
  auto const r = pixel_color.x();
  auto const g = pixel_color.y();
  auto const b = pixel_color.z();

  // Apply a linear to gamma transform for gamma 2
  auto const r_gamma = linear_to_gamma(r);
  auto const g_gamma = linear_to_gamma(g);
  auto const b_gamma = linear_to_gamma(b);

  // Translate the [0,1] component values to the byte range [0,255].
  static interval const intensity(0.000, 0.999);
  int const rbyte = int(256 * intensity.clamp(r_gamma));
  int const gbyte = int(256 * intensity.clamp(g_gamma));
  int const bbyte = int(256 * intensity.clamp(b_gamma));

  // Write out the pixel color components.
  out << rbyte << ' ' << gbyte << ' ' << bbyte << '\n';
}

#endif
