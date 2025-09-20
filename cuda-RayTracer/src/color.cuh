#ifndef COLOR_CUH
#define COLOR_CUH

#include "interval.cuh"
#include "vec3.cuh"

#ifdef __CUDACC__
#define CUDA_CALLABLE_MEMBER __host__ __device__
#else
#define CUDA_CALLABLE_MEMBER
#endif

using color = vec3;

CUDA_CALLABLE_MEMBER inline double linear_to_gamma(double linear_component) {
  if (linear_component > 0) { return sqrt(linear_component); }

  return 0;
}

#endif
