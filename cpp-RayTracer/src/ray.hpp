#ifndef RAY_HPP
#define RAY_HPP

#include "vec3.hpp"

class ray {
  public:
    ray() { }

    ray(point3 const & origin, vec3 const & direction) : orig(origin), dir(direction) { }

    point3 const & origin() const { return orig; }

    vec3 const & direction() const { return dir; }

    point3 at(double t) const { return orig + t * dir; }

  private:
    point3 orig;
    vec3 dir;
};

#endif
