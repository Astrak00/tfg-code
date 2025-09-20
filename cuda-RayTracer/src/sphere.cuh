#ifndef SPHERE_CUH
#define SPHERE_CUH

#include "hittable.cuh"

#ifdef __CUDACC__
#define CUDA_CALLABLE_MEMBER __host__ __device__
#else
#define CUDA_CALLABLE_MEMBER
#endif

class sphere : public hittable {
  public:
    CUDA_CALLABLE_MEMBER sphere(point3 const & center, double radius, material * mat)
      : center(center), radius(fmax(0, radius)), mat(mat) { }

    CUDA_CALLABLE_MEMBER bool hit(ray const & r, interval ray_t, hit_record & rec) const override {
      vec3 const oc  = center - r.origin();
      double const a = r.direction().length_squared();
      double const h = dot(r.direction(), oc);
      double const c = oc.length_squared() - radius * radius;

      double const discriminant = h * h - a * c;
      if (discriminant < 0) { return false; }

      double const sqrtd = sqrt(discriminant);

      // Find the nearest root that lies in the acceptable range.
      auto root = (h - sqrtd) / a;
      if (!ray_t.surrounds(root)) {
        root = (h + sqrtd) / a;
        if (!ray_t.surrounds(root)) { return false; }
      }

      rec.t               = root;
      rec.p               = r.at(rec.t);
      vec3 outward_normal = (rec.p - center) / radius;
      rec.set_face_normal(r, outward_normal);
      rec.mat = mat;

      return true;
    }

  private:
    point3 center;
    double radius;
    material * mat;
};

#endif
