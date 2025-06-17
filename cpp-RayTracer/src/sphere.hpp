#ifndef SPHERE_HPP
#define SPHERE_HPP

#include "hittable.hpp"

class sphere : public hittable {
  public:
    /**
       * @brief Constructs a sphere with the specified center, radius, and material.
       *
       * If the provided radius is negative, it is clamped to zero.
       */
      sphere(point3 const & center, double radius, shared_ptr<material> mat)
      : center(center), radius(std::fmax(0, radius)), mat(mat) { }

    /**
     * @brief Determines if a ray intersects the sphere within a given interval.
     *
     * If an intersection occurs within the specified ray parameter interval, populates the hit record with intersection details and returns true; otherwise, returns false.
     *
     * @param r The ray to test for intersection.
     * @param ray_t The interval of valid ray parameter values.
     * @param rec The hit record to populate if an intersection occurs.
     * @return true if the ray intersects the sphere within the interval; false otherwise.
     */
    bool hit(ray const & r, interval ray_t, hit_record & rec) const override {
      vec3 const oc  = center - r.origin();
      double const a = r.direction().length_squared();
      double const h = dot(r.direction(), oc);
      double const c = oc.length_squared() - radius * radius;

      double const discriminant = h * h - a * c;
      if (discriminant < 0) { return false; }

      double const sqrtd = std::sqrt(discriminant);

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
    shared_ptr<material> mat;
};

#endif
