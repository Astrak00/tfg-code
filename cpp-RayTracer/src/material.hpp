#ifndef MATERIAL_H
#define MATERIAL_H

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

    bool scatter(ray const & r_in, hit_record const & rec, color & attenuation,
                 ray & scattered) const override {
      attenuation = color(1.0, 1.0, 1.0);
      double ri   = rec.front_face ? (1.0 / refraction_index) : refraction_index;

      vec3 unit_direction = unit_vector(r_in.direction());
      double cos_theta    = std::fmin(dot(-unit_direction, rec.normal), 1.0);
      double sin_theta    = std::sqrt(1.0 - cos_theta * cos_theta);

      bool cannot_refract = ri * sin_theta > 1.0;
      vec3 direction;

      if (cannot_refract || reflectance(cos_theta, ri) > random_double()) {
        direction = reflect(unit_direction, rec.normal);
      } else {
        direction = refract(unit_direction, rec.normal, ri);
      }

      scattered = ray(rec.p, direction);
      return true;
    }

  private:
    // Refractive index in vacuum or air, or the ratio of the material's refractive index over
    // the refractive index of the enclosing media
    double refraction_index;

    static double reflectance(double cosine, double refraction_index) {
      // Use Schlick's approximation for reflectance.
      auto r0               = (1 - refraction_index) / (1 + refraction_index);
      r0                    = r0 * r0;
      double one_minus_cos  = 1.0 - cosine;
      double one_minus_cos2 = one_minus_cos * one_minus_cos;
      double one_minus_cos5 = one_minus_cos2 * one_minus_cos2 * one_minus_cos;
      return r0 + (1 - r0) * one_minus_cos5;
    }
};

#endif
