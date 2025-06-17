#ifndef MATERIAL_HPP
#define MATERIAL_HPP

#include "hittable.hpp"

class material {
  public:
    virtual ~material() = default;

    virtual bool scatter(ray const & r_in, hit_record const & rec, color & attenuation,
                         ray & scattered) const {
      return false;
    }
};

class lambertian : public material {
  public:
    lambertian(color const & albedo) : albedo(albedo) { }

    bool scatter(ray const & r_in, hit_record const & rec, color & attenuation,
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
    metal(color const & albedo, double fuzz) : albedo(albedo), fuzz(fuzz < 1 ? fuzz : 1) { }

    bool scatter(ray const & r_in, hit_record const & rec, color & attenuation,
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
    dielectric(double refraction_index) : refraction_index(refraction_index) { }

    /**
     * @brief Computes the scattering of a ray through a dielectric (transparent) material.
     *
     * Simulates refraction and reflection based on the material's refractive index, using Snell's law and Schlick's approximation to probabilistically determine whether the ray reflects or refracts. The scattered ray is set accordingly, and attenuation is always set to white (no color absorption).
     *
     * @param r_in Incoming ray.
     * @param rec Surface hit record containing intersection details.
     * @param attenuation Output color attenuation (always set to white).
     * @param scattered Output scattered ray (either reflected or refracted).
     * @return true Always returns true, indicating the ray is scattered.
     */
    bool scatter(ray const & r_in, hit_record const & rec, color & attenuation,
                 ray & scattered) const override {
      attenuation = color(1.0, 1.0, 1.0);
      double ri   = rec.front_face ? (1.0 / refraction_index) : refraction_index;

      vec3 const unit_direction = unit_vector(r_in.direction());
      double const cos_theta    = std::fmin(dot(-unit_direction, rec.normal), 1.0);
      double const sin_theta    = std::sqrt(1.0 - cos_theta * cos_theta);

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

    /**
     * @brief Computes the reflectance using Schlick's approximation.
     *
     * Calculates the proportion of light reflected at an interface between two media based on the incident angle cosine and the refractive index.
     *
     * @param cosine Cosine of the angle between the incident ray and the surface normal.
     * @param refraction_index Relative refractive index of the material.
     * @return double Estimated reflectance (fraction of reflected light).
     */
    static double reflectance(double cosine, double refraction_index) {
      // Use Schlick's approximation for reflectance.
      auto const r0               = (1 - refraction_index) / (1 + refraction_index);
      auto const r0_sq            = r0 * r0;
      double const one_minus_cos  = 1.0 - cosine;
      double const one_minus_cos2 = one_minus_cos * one_minus_cos;
      double const one_minus_cos5 = one_minus_cos2 * one_minus_cos2 * one_minus_cos;
      return r0_sq + (1 - r0_sq) * one_minus_cos5;
    }
};

#endif
