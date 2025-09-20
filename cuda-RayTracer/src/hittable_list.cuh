#ifndef HITTABLE_LIST_CUH
#define HITTABLE_LIST_CUH

#include "hittable.cuh"

#ifdef __CUDACC__
#define CUDA_CALLABLE_MEMBER __host__ __device__
#else
#define CUDA_CALLABLE_MEMBER
#endif

class hittable_list : public hittable {
  public:
    hittable ** objects;
    int size;

    CUDA_CALLABLE_MEMBER hittable_list() : objects(nullptr), size(0) { }

    CUDA_CALLABLE_MEMBER hittable_list(hittable ** objects, int size)
      : objects(objects), size(size) { }

    CUDA_CALLABLE_MEMBER bool hit(ray const & r, interval ray_t, hit_record & rec) const override {
      hit_record temp_rec;
      bool hit_anything   = false;
      auto closest_so_far = ray_t.max;

      for (int i = 0; i < size; i++) {
        if (objects[i]->hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
          hit_anything   = true;
          closest_so_far = temp_rec.t;
          rec            = temp_rec;
        }
      }

      return hit_anything;
    }
};

#endif
