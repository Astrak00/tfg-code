#ifndef RAY_HPP
#define RAY_HPP

#include "vec3.hpp"

class ray {
  public:
    ray() { }

    ray(point3 const & origin, vec3 const & direction) : orig(origin), dir(direction) { }

    point3 const & origin() const { return orig; }

    /**
 * @brief Returns the direction vector of the ray.
 *
 * @return Reference to the ray's direction vector.
 */
vec3 const & direction() const { return dir; }

    /**
 * @brief Computes the point along the ray at parameter t.
 *
 * @param t Scalar parameter indicating the distance from the ray's origin.
 * @return point3 The point at origin plus t times the direction vector.
 */
point3 const at(double t) const { return orig + t * dir; }

  private:
    point3 orig;
    vec3 dir;
};

#endif
