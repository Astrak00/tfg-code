#ifndef HITTABLE_LIST_HPP
#define HITTABLE_LIST_HPP

#include "hittable.hpp"

#include <vector>

class hittable_list : public hittable {
  public:
    std::vector<shared_ptr<hittable>> objects;

    /**
 * @brief Constructs an empty hittable list.
 */
hittable_list() { }

    /**
 * @brief Constructs a hittable_list containing a single hittable object.
 *
 * @param object Shared pointer to the hittable object to add to the list.
 */
hittable_list(shared_ptr<hittable> object) { add(object); }

    /**
 * @brief Removes all objects from the hittable list.
 */
void clear() { objects.clear(); }

    /**
 * @brief Adds a hittable object to the list.
 *
 * Appends the given hittable object to the collection managed by this list.
 */
void add(shared_ptr<hittable> object) { objects.push_back(object); }

    /**
     * @brief Determines if the ray intersects any object in the list within the given interval.
     *
     * Checks all contained hittable objects for intersections with the ray. If any object is hit within the interval, updates the hit record with the closest intersection and returns true; otherwise, returns false.
     *
     * @param r The ray to test for intersections.
     * @param ray_t The interval along the ray to consider for intersections.
     * @param rec Output parameter set to the closest hit record if an intersection occurs.
     * @return true if the ray hits any object in the list; false otherwise.
     */
    bool hit(ray const & r, interval ray_t, hit_record & rec) const override {
      hit_record temp_rec;
      bool hit_anything   = false;
      auto closest_so_far = ray_t.max;

      for (auto const & object : objects) {
        if (object->hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
          hit_anything   = true;
          closest_so_far = temp_rec.t;
          rec            = temp_rec;
        }
      }

      return hit_anything;
    }
};

#endif
