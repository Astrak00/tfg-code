#ifndef VEC3_CUH
#define VEC3_CUH

#include <cmath>
#include <iostream>

#ifdef __CUDACC__
#define CUDA_CALLABLE_MEMBER __host__ __device__
#else
#define CUDA_CALLABLE_MEMBER
#endif

class vec3 {
  public:
    double e[3];

    CUDA_CALLABLE_MEMBER vec3() : e{0, 0, 0} { }

    CUDA_CALLABLE_MEMBER vec3(double e0, double e1, double e2) : e{e0, e1, e2} { }

    CUDA_CALLABLE_MEMBER double x() const { return e[0]; }

    CUDA_CALLABLE_MEMBER double y() const { return e[1]; }

    CUDA_CALLABLE_MEMBER double z() const { return e[2]; }

    CUDA_CALLABLE_MEMBER vec3 operator-() const { return vec3(-e[0], -e[1], -e[2]); }

    CUDA_CALLABLE_MEMBER double operator[](int i) const { return e[i]; }

    CUDA_CALLABLE_MEMBER double & operator[](int i) { return e[i]; }

    CUDA_CALLABLE_MEMBER vec3 & operator+=(vec3 const & v) {
      e[0] += v.e[0];
      e[1] += v.e[1];
      e[2] += v.e[2];
      return *this;
    }

    CUDA_CALLABLE_MEMBER vec3 & operator*=(double t) {
      e[0] *= t;
      e[1] *= t;
      e[2] *= t;
      return *this;
    }

    CUDA_CALLABLE_MEMBER vec3 & operator/=(double t) { return *this *= 1 / t; }

    CUDA_CALLABLE_MEMBER double length() const { return sqrt(length_squared()); }

    CUDA_CALLABLE_MEMBER double length_squared() const {
      return e[0] * e[0] + e[1] * e[1] + e[2] * e[2];
    }

    CUDA_CALLABLE_MEMBER bool near_zero() const {
      // Return true if the vector is close to zero in all dimensions.
      auto s = 1e-8;
      return (fabs(e[0]) < s) && (fabs(e[1]) < s) && (fabs(e[2]) < s);
    }

    // It is not possible to have static members in a __device__ class
};

// point3 is just an alias for vec3, but useful for geometric clarity in the code.
using point3 = vec3;

// Vector Utility Functions

inline CUDA_CALLABLE_MEMBER vec3 operator+(vec3 const & u, vec3 const & v) {
  return vec3(u.e[0] + v.e[0], u.e[1] + v.e[1], u.e[2] + v.e[2]);
}

inline CUDA_CALLABLE_MEMBER vec3 operator-(vec3 const & u, vec3 const & v) {
  return vec3(u.e[0] - v.e[0], u.e[1] - v.e[1], u.e[2] - v.e[2]);
}

inline CUDA_CALLABLE_MEMBER vec3 operator*(vec3 const & u, vec3 const & v) {
  return vec3(u.e[0] * v.e[0], u.e[1] * v.e[1], u.e[2] * v.e[2]);
}

inline CUDA_CALLABLE_MEMBER vec3 operator*(double t, vec3 const & v) {
  return vec3(t * v.e[0], t * v.e[1], t * v.e[2]);
}

inline CUDA_CALLABLE_MEMBER vec3 operator*(vec3 const & v, double t) {
  return t * v;
}

inline CUDA_CALLABLE_MEMBER vec3 operator/(vec3 const & v, double t) {
  return (1 / t) * v;
}

inline CUDA_CALLABLE_MEMBER double dot(vec3 const & u, vec3 const & v) {
  return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
}

inline CUDA_CALLABLE_MEMBER vec3 cross(vec3 const & u, vec3 const & v) {
  return vec3(u.e[1] * v.e[2] - u.e[2] * v.e[1], u.e[2] * v.e[0] - u.e[0] * v.e[2],
              u.e[0] * v.e[1] - u.e[1] * v.e[0]);
}

inline CUDA_CALLABLE_MEMBER vec3 unit_vector(vec3 const & v) {
  return v / v.length();
}

inline CUDA_CALLABLE_MEMBER vec3 reflect(vec3 const & v, vec3 const & n) {
  return v - 2 * dot(v, n) * n;
}

inline CUDA_CALLABLE_MEMBER vec3 refract(vec3 const & uv, vec3 const & n, double etai_over_etat) {
  auto cos_theta      = fmin(dot(-uv, n), 1.0);
  vec3 r_out_perp     = etai_over_etat * (uv + cos_theta * n);
  vec3 r_out_parallel = -sqrt(fabs(1.0 - r_out_perp.length_squared())) * n;
  return r_out_perp + r_out_parallel;
}

#endif
