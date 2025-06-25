#ifndef HITTABLE_CUH
#define HITTABLE_CUH

#include "ray.cuh"

#ifdef __CUDACC__
#define CUDA_CALLABLE_MEMBER __host__ __device__
#else
#define CUDA_CALLABLE_MEMBER
#endif

class material;

class hit_record {
  public:
    point3 p;
    vec3 normal;
    material * mat;
    double t;
    bool front_face;

    CUDA_CALLABLE_MEMBER void set_face_normal(ray const & r, vec3 const & outward_normal) {
      // Sets the hit record normal vector.
      // NOTE: the parameter `outward_normal` is assumed to have unit length.

      front_face = dot(r.direction(), outward_normal) < 0;
      normal     = front_face ? outward_normal : -outward_normal;
    }
};

class hittable {
  public:
    CUDA_CALLABLE_MEMBER virtual bool hit(ray const & r, interval ray_t, hit_record & rec) const = 0;
};

#endif
