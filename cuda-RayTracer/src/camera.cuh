#ifndef CAMERA_CUH
#define CAMERA_CUH

#include "hittable.cuh"
#include "material.cuh"
#include "rtweekend.cuh"

#ifdef __CUDACC__
#define CUDA_CALLABLE_MEMBER __host__ __device__
#else
#define CUDA_CALLABLE_MEMBER
#endif

class camera {
  public:
    double aspect_ratio   = 1.0;  // Ratio of image width over height
    int image_width       = 100;  // Rendered image width in pixel count
    int samples_per_pixel = 10;   // Count of random samples for each pixel
    int max_depth         = 10;   // Maximum number of ray bounces into scene

    double vfov     = 90;                // Vertical view angle (field of view)
    point3 lookfrom = point3(0, 0, 0);   // Point camera is looking from
    point3 lookat   = point3(0, 0, -1);  // Point camera is looking at
    vec3 vup        = vec3(0, 1, 0);     // Camera-relative "up" direction

    double defocus_angle = 0;   // Variation angle of rays through each pixel
    double focus_dist    = 10;  // Distance from camera lookfrom point to plane of perfect focus

    CUDA_CALLABLE_MEMBER void initialize() {
      image_height = int(image_width / aspect_ratio);
      image_height = (image_height < 1) ? 1 : image_height;

      pixel_samples_scale = 1.0 / samples_per_pixel;

      center = lookfrom;

      // Determine viewport dimensions.
      double const theta           = degrees_to_radians(vfov);
      double const h               = tan(theta / 2);
      double const viewport_height = 2 * h * focus_dist;
      double const viewport_width  = viewport_height * (double(image_width) / image_height);

      // Calculate the u,v,w unit basis vectors for the camera coordinate frame.
      w = unit_vector(lookfrom - lookat);
      u = unit_vector(cross(vup, w));
      v = cross(w, u);

      // Calculate the vectors across the horizontal and down the vertical viewport edges.
      vec3 const viewport_u = viewport_width * u;    // Vector across viewport horizontal edge
      vec3 const viewport_v = viewport_height * -v;  // Vector down viewport vertical edge

      // Calculate the horizontal and vertical delta vectors from pixel to pixel.
      pixel_delta_u = viewport_u / image_width;
      pixel_delta_v = viewport_v / image_height;

      // Calculate the location of the upper left pixel.
      auto const viewport_upper_left = center - (focus_dist * w) - viewport_u / 2 - viewport_v / 2;
      pixel00_loc                    = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v);

      // Calculate the camera defocus disk basis vectors.
      auto const defocus_radius = focus_dist * tan(degrees_to_radians(defocus_angle / 2));
      defocus_disk_u            = u * defocus_radius;
      defocus_disk_v            = v * defocus_radius;
    }

    CUDA_CALLABLE_MEMBER ray get_ray(int i, int j, curandState * local_rand_state) const {
      // Construct a camera ray originating from the defocus disk and directed at a randomly
      // sampled point around the pixel location i, j.

      auto const offset = sample_square(local_rand_state);
      auto const pixel_sample =
          pixel00_loc + ((i + offset.x()) * pixel_delta_u) + ((j + offset.y()) * pixel_delta_v);

      auto const ray_origin    = (defocus_angle <= 0) ? center : defocus_disk_sample(local_rand_state);
      auto const ray_direction = pixel_sample - ray_origin;

      return ray(ray_origin, ray_direction);
    }

    CUDA_CALLABLE_MEMBER color ray_color(ray const & r, int depth, hittable const & world,
                                         curandState * local_rand_state) const {
      // If we've exceeded the ray bounce limit, no more light is gathered.
      if (depth <= 0) { return color(0, 0, 0); }

      hit_record rec;

      if (world.hit(r, interval(0.001, infinity), rec)) {
        ray scattered;
        color attenuation;
        if (rec.mat->scatter(r, rec, attenuation, scattered)) {
          return attenuation * ray_color(scattered, depth - 1, world, local_rand_state);
        }
        return color(0, 0, 0);
      }

      vec3 const unit_direction = unit_vector(r.direction());
      auto const a              = 0.5 * (unit_direction.y() + 1.0);
      return (1.0 - a) * color(1.0, 1.0, 1.0) + a * color(0.5, 0.7, 1.0);
    }

  private:
    int image_height;            // Rendered image height
    double pixel_samples_scale;  // Color scale factor for a sum of pixel samples
    point3 center;               // Camera center
    point3 pixel00_loc;          // Location of pixel 0, 0
    vec3 pixel_delta_u;          // Offset to pixel to the right
    vec3 pixel_delta_v;          // Offset to pixel below
    vec3 u, v, w;                // Camera frame basis vectors
    vec3 defocus_disk_u;         // Defocus disk horizontal radius
    vec3 defocus_disk_v;         // Defocus disk vertical radius

    CUDA_CALLABLE_MEMBER vec3 sample_square(curandState * local_rand_state) const {
      // Returns the vector to a random point in the [-.5,-.5]-[+.5,+.5] unit square.
      return vec3(random_double(local_rand_state) - 0.5, random_double(local_rand_state) - 0.5, 0);
    }

    CUDA_CALLABLE_MEMBER point3 defocus_disk_sample(curandState * local_rand_state) const {
      // Returns a random point in the camera defocus disk.
      vec3 const p = random_in_unit_disk(local_rand_state);
      return center + (p[0] * defocus_disk_u) + (p[1] * defocus_disk_v);
    }
};

#endif
