#ifndef HITTABLE_HPP
#define HITTABLE_HPP

class material;

class hit_record {
  public:
    point3 p;
    vec3 normal;
    shared_ptr<material> mat;
    double t;
    bool front_face;

    void set_face_normal(ray const & r, vec3 const & outward_normal) {
      // Sets the hit record normal vector.
      // NOTE: the parameter `outward_normal` is assumed to have unit length.

      front_face = dot(r.direction(), outward_normal) < 0;
      normal     = front_face ? outward_normal : -outward_normal;
    }
};

class hittable {
  public:
    virtual ~hittable() = default;

    virtual bool hit(ray const & r, interval ray_t, hit_record & rec) const = 0;
};

#endif
