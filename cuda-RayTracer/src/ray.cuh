#ifndef RAY_CUH
#define RAY_CUH

#include "vec3.cuh"

#ifdef __CUDACC__
#define CUDA_CALLABLE_MEMBER __host__ __device__
#else
#define CUDA_CALLABLE_MEMBER
#endif

class ray {
  public:
    CUDA_CALLABLE_MEMBER ray() { }

    CUDA_CALLABLE_MEMBER ray(point3 const & origin, vec3 const & direction)
      : orig(origin), dir(direction) { }

    CUDA_CALLABLE_MEMBER point3 const & origin() const { return orig; }

    CUDA_CALLABLE_MEMBER vec3 const & direction() const { return dir; }

    CUDA_CALLABLE_MEMBER point3 const at(double t) const { return orig + t * dir; }

  private:
    point3 orig;
    vec3 dir;
};

#endif
