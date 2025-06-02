#include "rtweekend.h"

// Only include OpenMP if it's available and enabled
#if defined(_OPENMP) && defined(ENABLE_OPENMP)
  #include <omp.h>
#endif
#include <fstream>
#include <sstream>
#include <string>

int main(int argc, char * argv[]) {
  // Default path for sphere data
  std::string sphere_data_path = "sphere_data.txt";
  std::string output_ppm_path  = "cpp_spheres.ppm";

  // Process command-line arguments
  for (int i = 1; i < argc; i++) {
    // Convert to string_view to avoid unnecessary string construction
    std::string_view arg(argv[i]);

    if (arg == "--path") {
      if (i + 1 < argc) {
        sphere_data_path = argv[i + 1];
        i++;  // Skip the next argument (the path value)
      } else {
        std::cerr << "Error: --path requires a value\n";
        return 1;  // or handle error appropriately
      }
    } else if (arg == "--output") {
      if (i + 1 < argc) {
        output_ppm_path = argv[i + 1];
        i++;
      } else {
        std::cerr << "Error: --output requires a value\n";
        return 1;
      }
    }
#if defined(_OPENMP) && defined(ENABLE_OPENMP)
    else if (arg == "--cores") {
      if (i + 1 < argc) {
        try {
          int cores = std::stoi(argv[i + 1]);
          if (cores > 0) {
            omp_set_num_threads(cores);
          } else {
            std::cerr << "Error: --cores must be a positive integer\n";
            return 1;
          }
          i++;  // Skip the next argument (the cores value)
        } catch (std::exception const & e) {
          std::cerr << "Error: Invalid number for --cores: " << argv[i + 1] << "\n";
          return 1;
        }
      } else {
        std::cerr << "Error: --cores requires a value\n";
        return 1;
      }
    }
#endif
    else if (arg == "--help" || arg == "-h") {
      std::cout << "Usage: " << argv[0]
                << " [--path <sphere_data_path>] [--output <output_ppm_path>]"
#if defined(_OPENMP) && defined(ENABLE_OPENMP)
                << " [--cores <num_cores>]"
#endif
                << "\n";
      std::cout << "Default sphere data path: " << sphere_data_path << "\n";
      std::cout << "Default output PPM path: " << output_ppm_path << "\n";
      return 0;  // Exit after showing help
    } else {
      std::cerr << "Error: Unknown argument: " << arg << "\n";
      std::cerr << "Use --help for usage information\n";
      return 1;
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
  std::cout << "Loaded world from" << sphere_data_path << "\n";
  infile.close();

  // Create the output path file
  std::ofstream output_ppm_file(output_ppm_path);
  if (!output_ppm_file.is_open()) {
    std::cerr << "Could not open output file: " << output_ppm_path << std::endl;
    return 1;
  }

  cam.render(world, output_ppm_file);
}
