#ifndef RTWEEKEND_CUH
#define RTWEEKEND_CUH

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <limits>

#ifdef __CUDACC__
#include <curand_kernel.h>
#define CUDA_CALLABLE_MEMBER __host__ __device__
#else
#define CUDA_CALLABLE_MEMBER
#endif

// Common Headers
#include "color.cuh"
#include "interval.cuh"
#include "ray.cuh"
#include "vec3.cuh"

// Constants
constexpr double infinity = 1e30;
constexpr double pi       = 3.1415926535897932385;

// Utility Functions

CUDA_CALLABLE_MEMBER inline double constexpr degrees_to_radians(double degrees) {
  return degrees * pi / 180.0;
}

__device__ inline double random_double(curandState * local_rand_state) {
  return curand_uniform(local_rand_state);
}

__device__ inline vec3 random_unit_vector(curandState * local_rand_state) {
  double a = curand_uniform(local_rand_state) * 2.0 * pi;
  double z = -1.0 + 2.0 * curand_uniform(local_rand_state);
  double r = sqrt(1.0 - z * z);
  return vec3(r * cos(a), r * sin(a), z);
}

__device__ inline vec3 random_in_unit_disk(curandState * local_rand_state) {
  while (true) {
    auto p = vec3(random_double(local_rand_state), random_double(local_rand_state), 0);
    if (p.length_squared() < 1) { return p; }
  }
}

#include "camera.cuh"
#include "hittable.cuh"
#include "hittable_list.cuh"
#include "material.cuh"
#include "sphere.cuh"

#endif
