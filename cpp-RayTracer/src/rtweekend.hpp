#ifndef RTWEEKEND_H
#define RTWEEKEND_H

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <memory>
#include <random>
#include <thread>

// C++ Std Usings

using std::make_shared;
using std::shared_ptr;

// Constants
#ifdef __FAST_MATH__
// When fast-math is enabled, use a very large finite value instead of infinity
constexpr double infinity = 1e30;
#else
constexpr double infinity = std::numeric_limits<double>::infinity();
#endif

#if __cplusplus >= 202002L
  #include <numbers>
constexpr double pi = std::numbers::pi;
#else
constexpr double pi = 3.1415926535897932385;
#endif

// Utility Functions

inline double degrees_to_radians(double degrees) {
  return degrees * pi / 180.0;
}

inline double random_double() {
  thread_local static std::mt19937 generator(
      std::random_device{}() + std::hash<std::thread::id>{}(std::this_thread::get_id()));
  thread_local static std::uniform_real_distribution<double> distribution(0.0, 1.0);
  return distribution(generator);
}

inline double random_double(double min, double max) {
  // Returns a random real in [min,max).
  return min + (max - min) * random_double();
}

// Common Headers

// clang-format off
// NOLINTBEGIN
#include "color.hpp"
#include "interval.hpp"
#include "ray.hpp"
#include "vec3.hpp"

#include "camera.hpp"
#include "hittable.hpp"
#include "hittable_list.hpp"
#include "material.hpp"
#include "sphere.hpp"
// NOLINTEND
// clang-format on

#endif
