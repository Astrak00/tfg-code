//==============================================================================================
// Originally written in 2016 by Peter Shirley <ptrshrl@gmail.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and related and
// neighboring rights to this software to the public domain worldwide. This software is
// distributed without any warranty.
//
// You should have received a copy (see file COPYING.txt) of the CC0 Public Domain Dedication
// along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
//==============================================================================================
#include "rtweekend.h"
#include "camera.h"
#include "hittable.h"
#include "hittable_list.h"
#include "material.h"
#include "sphere.h"

#include <fstream>
#include <sstream>
#include <string>

int main(int argc, char * argv[]) {
  // Default path for sphere data
  std::string sphere_data_path = "sphere_data.txt";

  // Process command-line arguments
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--path") == 0) {
      if (i + 1 < argc) {
        sphere_data_path = argv[i + 1];
        i++;  // Skip the next argument (the path value)
      }
    }
  }

  hittable_list world;
  camera cam;

  // Default camera settings
  cam.aspect_ratio      = 16.0 / 9.0;
  cam.image_width       = 800;
  cam.samples_per_pixel = 50;
  cam.max_depth         = 50;
  cam.vfov              = 20;
  cam.lookfrom          = point3(13, 2, 3);
  cam.lookat            = point3(0, 0, 0);
  cam.vup               = vec3(0, 1, 0);
  cam.defocus_angle     = 0.6;
  cam.focus_dist        = 10.0;

  auto ground_material = make_shared<lambertian>(color(0.5, 0.5, 0.5));
  world.add(make_shared<sphere>(point3(0, -1000, 0), 1000, ground_material));

  {
    std::ifstream infile(sphere_data_path);
    if (!infile.is_open()) {
      std::cerr << "Could not open file: " << sphere_data_path << std::endl;
      return 1;
    }
    std::string line;
    while (std::getline(infile, line)) {
      if (line.empty() || line[0] == '#') { continue; }
      std::istringstream iss(line);

      // Check if this is a camera parameter line (starts with 'c')
      std::string first_token;
      iss >> first_token;

      if (first_token == "c") {
        std::string param_name;
        iss >> param_name;

        if (param_name == "ratio") {
          double width, height;
          if (iss >> width >> height) { cam.aspect_ratio = width / height; }
        } else if (param_name == "width") {
          int width;
          if (iss >> width) { cam.image_width = width; }
        } else if (param_name == "samplesPerPixel") {
          int samples;
          if (iss >> samples) { cam.samples_per_pixel = samples; }
        } else if (param_name == "maxDepth") {
          int depth;
          if (iss >> depth) { cam.max_depth = depth; }
        } else if (param_name == "vfov") {
          double vfov;
          if (iss >> vfov) { cam.vfov = vfov; }
        } else if (param_name == "lookFrom") {
          double x, y, z;
          if (iss >> x >> y >> z) { cam.lookfrom = point3(x, y, z); }
        } else if (param_name == "lookAt") {
          double x, y, z;
          if (iss >> x >> y >> z) { cam.lookat = point3(x, y, z); }
        } else if (param_name == "vup") {
          double x, y, z;
          if (iss >> x >> y >> z) { cam.vup = vec3(x, y, z); }
        } else if (param_name == "defocusAngle") {
          double angle;
          if (iss >> angle) { cam.defocus_angle = angle; }
        } else if (param_name == "focusDist") {
          double dist;
          if (iss >> dist) { cam.focus_dist = dist; }
        }
        continue;
      }

      // Reset the stream to process non-camera lines
      iss.clear();
      iss.seekg(0);

      double x, y, z, radius;
      std::string material_type;
      if (!(iss >> x >> y >> z >> radius >> material_type)) {
        continue;  // Skip if line is malformed
      }
      shared_ptr<material> sphere_material;
      if (material_type == "lambertian") {
        double r, g, b;
        if (!(iss >> r >> g >> b)) { continue; }
        sphere_material = make_shared<lambertian>(color(r, g, b));
      } else if (material_type == "metal") {
        double r, g, b, fuzz;
        if (!(iss >> r >> g >> b >> fuzz)) { continue; }
        sphere_material = make_shared<metal>(color(r, g, b), fuzz);
      } else if (material_type == "dielectric") {
        double index;
        if (!(iss >> index)) { continue; }
        sphere_material = make_shared<dielectric>(index);
      } else {
        continue;  // Skip unknown material types
      }
      point3 center(x, y, z);
      world.add(make_shared<sphere>(center, radius, sphere_material));
    }
  }

  cam.render(world);
}
