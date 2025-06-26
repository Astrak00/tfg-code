#include "rtweekend.cuh"

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

#include <cuda_runtime.h>

// CUDA kernel to render the scene
__global__ void render_kernel(vec3 * fb, int max_x, int max_y, camera * cam, hittable * world,
                              curandState * rand_state) {
  int i = threadIdx.x + blockIdx.x * blockDim.x;
  int j = threadIdx.y + blockIdx.y * blockDim.y;

  if ((i >= max_x) || (j >= max_y)) return;

  int pixel_index = j * max_x + i;

  curandState local_rand_state = rand_state[pixel_index];

  color pixel_color(0, 0, 0);
  for (int sample = 0; sample < cam->samples_per_pixel; sample++) {
    ray const r = cam->get_ray(i, j, &local_rand_state);
    pixel_color += cam->ray_color(r, cam->max_depth, *world, &local_rand_state);
  }
  fb[pixel_index] = pixel_color;

  rand_state[pixel_index] = local_rand_state;
}

int main(int argc, char * argv[]) {
  // Default path for sphere data
  std::string sphere_data_path = "sphere_data.txt";
  std::string output_ppm_path  = "cuda_spheres.ppm";

  // Process command-line arguments
  for (int i = 1; i < argc; i++) {
    std::string_view arg(argv[i]);

    if (arg == "--path") {
      if (i + 1 < argc) {
        sphere_data_path = argv[i + 1];
        i++;
      } else {
        std::cerr << "Error: --path requires a value\n";
        return 1;
      }
    } else if (arg == "--output") {
      if (i + 1 < argc) {
        output_ppm_path = argv[i + 1];
        i++;
      } else {
        std::cerr << "Error: --output requires a value\n";
        return 1;
      }
    } else if (arg == "--help" || arg == "-h") {
      std::cout << "Usage: " << argv[0]
                << " [--path <sphere_data_path>] [--output <output_ppm_path>]\n";
      std::cout << "Default sphere data path: " << sphere_data_path << "\n";
      std::cout << "Default output PPM path: " << output_ppm_path << "\n";
      return 0;
    } else {
      std::cerr << "Error: Unknown argument: " << arg << "\n";
      std::cerr << "Use --help for usage information\n";
      return 1;
    }
  }

  // World and camera setup
  std::vector<hittable *> hittable_objects;
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
        if (iss >> x >> y >> z) { cam.vup = vec3(0, 1, 0); }
      } else if (param_name == "defocusAngle") {
        double angle;
        if (iss >> angle) { cam.defocus_angle = angle; }
      } else if (param_name == "focusDist") {
        double dist;
        if (iss >> dist) { cam.focus_dist = dist; }
      }
      continue;
    }

    iss.clear();
    iss.seekg(0);

    double x, y, z, radius;
    std::string material_type;
    if (!(iss >> x >> y >> z >> radius >> material_type)) { continue; }

    material * sphere_material;
    if (material_type == "lambertian") {
      double r, g, b;
      if (!(iss >> r >> g >> b)) { continue; }
      sphere_material = new lambertian(color(r, g, b));
    } else if (material_type == "metal") {
      double r, g, b, fuzz;
      if (!(iss >> r >> g >> b >> fuzz)) { continue; }
      sphere_material = new metal(color(r, g, b), fuzz);
    } else if (material_type == "dielectric") {
      double index;
      if (!(iss >> index)) { continue; }
      sphere_material = new dielectric(index);
    } else {
      continue;
    }
    point3 const center(x, y, z);
    hittable_objects.push_back(new sphere(center, radius, sphere_material));
  }
  std::cout << "Loaded world from " << sphere_data_path << "\n";
  infile.close();

  cam.initialize();

  // Allocate memory on the device
  int image_height = static_cast<int>(cam.image_width / cam.aspect_ratio);
  int num_pixels   = cam.image_width * image_height;
  vec3 * fb;
  cudaMallocManaged(&fb, num_pixels * sizeof(vec3));

  camera * dev_cam;
  cudaMallocManaged(&dev_cam, sizeof(camera));
  *dev_cam = cam;

  hittable ** dev_list;
  cudaMallocManaged(&dev_list, hittable_objects.size() * sizeof(hittable *));
  for (size_t i = 0; i < hittable_objects.size(); ++i) {
    cudaMallocManaged(&dev_list[i], sizeof(hittable));
    *dev_list[i] = *hittable_objects[i];
  }

  hittable * dev_world;
  cudaMallocManaged(&dev_world, sizeof(hittable_list));
  *(hittable_list *)dev_world = hittable_list(dev_list, hittable_objects.size());

  curandState * dev_rand_state;
  cudaMallocManaged(&dev_rand_state, num_pixels * sizeof(curandState));

  // Kernel launch
  dim3 blocks(cam.image_width / 16, image_height / 16);
  dim3 threads(16, 16);
  render_kernel<<<blocks, threads>>>(fb, cam.image_width, image_height, dev_cam, dev_world,
                                     dev_rand_state);
  cudaDeviceSynchronize();

  // Write image to file
  std::ofstream output_ppm_file(output_ppm_path);
  if (!output_ppm_file.is_open()) {
    std::cerr << "Could not open output file: " << output_ppm_path << std::endl;
    return 1;
  }

  output_ppm_file << "P3\n" << cam.image_width << " " << image_height << "\n255\n";
  for (int j = 0; j < image_height; j++) {
    for (int i = 0; i < cam.image_width; i++) {
      int pixel_index = j * cam.image_width + i;
      write_color(output_ppm_file, fb[pixel_index], cam.samples_per_pixel);
    }
  }

  // Free device memory
  cudaFree(fb);
  cudaFree(dev_cam);
  for (size_t i = 0; i < hittable_objects.size(); ++i) { cudaFree(dev_list[i]); }
  cudaFree(dev_list);
  cudaFree(dev_world);
  cudaFree(dev_rand_state);

  for (auto & obj : hittable_objects) { delete obj; }
}
