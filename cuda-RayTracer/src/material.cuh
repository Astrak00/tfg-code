#ifndef MATERIAL_CUH
#define MATERIAL_CUH

#include "hittable.cuh"
#include "rtweekend.cuh"

#ifdef __CUDACC__
#define CUDA_CALLABLE_MEMBER __host__ __device__
#else
#define CUDA_CALLABLE_MEMBER
#endif

class material {
  public:
    CUDA_CALLABLE_MEMBER virtual bool scatter(ray const & r_in, hit_record const & rec,
                                              color & attenuation,
                                              ray & scattered) const = 0;
};

class lambertian : public material {
  public:
    CUDA_CALLABLE_MEMBER lambertian(color const & albedo) : albedo(albedo) { }

    CUDA_CALLABLE_MEMBER bool scatter(ray const & r_in, hit_record const & rec,
                                      color & attenuation,
                                      ray & scattered) const override {
      auto scatter_direction = rec.normal + random_unit_vector();

      // Catch degenerate scatter direction
      if (scatter_direction.near_zero()) { scatter_direction = rec.normal; }

      scattered   = ray(rec.p, scatter_direction);
      attenuation = albedo;
      return true;
    }

  private:
    color albedo;
};

class metal : public material {
  public:
    CUDA_CALLABLE_MEMBER metal(color const & albedo, double fuzz)
      : albedo(albedo), fuzz(fuzz < 1 ? fuzz : 1) { }

    CUDA_CALLABLE_MEMBER bool scatter(ray const & r_in, hit_record const & rec,
                                      color & attenuation,
                                      ray & scattered) const override {
      vec3 reflected = reflect(r_in.direction(), rec.normal);
      reflected      = unit_vector(reflected) + (fuzz * random_unit_vector());
      scattered      = ray(rec.p, reflected);
      attenuation    = albedo;
      return (dot(scattered.direction(), rec.normal) > 0);
    }

  private:
    color albedo;
    double fuzz;
};

class dielectric : public material {
  public:
    CUDA_CALLABLE_MEMBER dielectric(double refraction_index) : refraction_index(refraction_index) { }

    CUDA_CALLABLE_MEMBER bool scatter(ray const & r_in, hit_record const & rec,
                                      color & attenuation,
                                      ray & scattered) const override {
      attenuation = color(1.0, 1.0, 1.0);
      double ri   = rec.front_face ? (1.0 / refraction_index) : refraction_index;

      vec3 const unit_direction = unit_vector(r_in.direction());
      double const cos_theta    = fmin(dot(-unit_direction, rec.normal), 1.0);
      double const sin_theta    = sqrt(1.0 - cos_theta * cos_theta);

      bool const cannot_refract = ri * sin_theta > 1.0;

      if (cannot_refract || reflectance(cos_theta, ri) > random_double()) {
        vec3 const direction = reflect(unit_direction, rec.normal);
        scattered            = ray(rec.p, direction);
      } else {
        vec3 const direction = refract(unit_direction, rec.normal, ri);
        scattered            = ray(rec.p, direction);
      }

      return true;
    }

  private:
    // Refractive index in vacuum or air, or the ratio of the material's refractive index over
    // the refractive index of the enclosing media
    double refraction_index;

    CUDA_CALLABLE_MEMBER double reflectance(double cosine, double refraction_index) const {
      // Use Schlick's approximation for reflectance.
      auto r0 = (1 - refraction_index) / (1 + refraction_index);
      r0      = r0 * r0;
      return r0 + (1 - r0) * pow((1 - cosine), 5);
    }
};

#endif
