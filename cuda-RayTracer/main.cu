#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <cstdint>
#include <vector>
#include <string>
#include <fstream>
#include <sstream>
#include <iostream>
#include <algorithm>

// ---------------------------------------------
// Minimal math (float-based for GPU performance)
// ---------------------------------------------

struct Vec3
{
    float x, y, z;
    __host__ __device__ Vec3() : x(0), y(0), z(0) {}
    __host__ __device__ Vec3(float x_, float y_, float z_) : x(x_), y(y_), z(z_) {}
    __host__ __device__ Vec3 operator-() const { return Vec3(-x, -y, -z); }
    __host__ __device__ Vec3 &operator+=(const Vec3 &v)
    {
        x += v.x;
        y += v.y;
        z += v.z;
        return *this;
    }
    __host__ __device__ Vec3 &operator*=(float t)
    {
        x *= t;
        y *= t;
        z *= t;
        return *this;
    }
    __host__ __device__ Vec3 &operator/=(float t) { return *this *= (1.0f / t); }
    __host__ __device__ float length() const { return sqrtf(x * x + y * y + z * z); }
    __host__ __device__ float length_squared() const { return x * x + y * y + z * z; }
    __host__ __device__ bool near_zero() const
    {
        const float s = 1e-8f;
        return fabsf(x) < s && fabsf(y) < s && fabsf(z) < s;
    }
};

__host__ __device__ inline Vec3 operator+(const Vec3 &a, const Vec3 &b) { return Vec3(a.x + b.x, a.y + b.y, a.z + b.z); }
__host__ __device__ inline Vec3 operator-(const Vec3 &a, const Vec3 &b) { return Vec3(a.x - b.x, a.y - b.y, a.z - b.z); }
__host__ __device__ inline Vec3 operator*(const Vec3 &a, const Vec3 &b) { return Vec3(a.x * b.x, a.y * b.y, a.z * b.z); }
__host__ __device__ inline Vec3 operator*(float t, const Vec3 &v) { return Vec3(t * v.x, t * v.y, t * v.z); }
__host__ __device__ inline Vec3 operator*(const Vec3 &v, float t) { return t * v; }
__host__ __device__ inline Vec3 operator/(const Vec3 &v, float t) { return (1.0f / t) * v; }
__host__ __device__ inline float dot(const Vec3 &a, const Vec3 &b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
__host__ __device__ inline Vec3 cross(const Vec3 &a, const Vec3 &b) { return Vec3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x); }
__host__ __device__ inline Vec3 unit_vector(const Vec3 &v)
{
    float len = v.length();
    return len > 0 ? v / len : v;
}
__host__ __device__ inline Vec3 reflect(const Vec3 &v, const Vec3 &n) { return v - 2.0f * dot(v, n) * n; }
__host__ __device__ inline Vec3 refract(const Vec3 &uv, const Vec3 &n, float etai_over_etat)
{
    float cos_theta = fminf(dot(-uv, n), 1.0f);
    Vec3 r_out_perp = etai_over_etat * (uv + cos_theta * n);
    Vec3 r_out_parallel = -sqrtf(fabsf(1.0f - r_out_perp.length_squared())) * n;
    return r_out_perp + r_out_parallel;
}

// ---------------------------------------------
// RNG (xorshift32 per thread)
// ---------------------------------------------

struct RNG
{
    unsigned int state;
};

__device__ inline unsigned int xorshift(RNG &rng)
{
    unsigned int x = rng.state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    rng.state = x ? x : 1u;
    return rng.state;
}

__device__ inline float randf(RNG &rng)
{
    return (xorshift(rng) & 0x00FFFFFF) / 16777216.0f; // [0,1)
}

__device__ inline Vec3 random_in_unit_disk(RNG &rng)
{
    while (true)
    {
        float x = 2.0f * randf(rng) - 1.0f;
        float y = 2.0f * randf(rng) - 1.0f;
        if (x * x + y * y < 1.0f)
            return Vec3(x, y, 0.0f);
    }
}

__device__ inline Vec3 random_unit_vector(RNG &rng)
{
    while (true)
    {
        float x = 2.0f * randf(rng) - 1.0f;
        float y = 2.0f * randf(rng) - 1.0f;
        float z = 2.0f * randf(rng) - 1.0f;
        float lsq = x * x + y * y + z * z;
        if (lsq > 1e-16f && lsq <= 1.0f)
        {
            float inv = rsqrtf(lsq);
            return Vec3(x * inv, y * inv, z * inv);
        }
    }
}

// ---------------------------------------------
// Ray, Camera
// ---------------------------------------------

struct Ray
{
    Vec3 orig;
    Vec3 dir;
    __host__ __device__ Ray() {}
    __host__ __device__ Ray(const Vec3 &o, const Vec3 &d) : orig(o), dir(d) {}
    __host__ __device__ Vec3 at(float t) const { return orig + t * dir; }
};

struct CameraData
{
    int image_width;
    int image_height;
    int samples_per_pixel;
    int max_depth;
    float defocus_angle;
    float focus_dist;
    Vec3 center;
    Vec3 pixel00_loc;
    Vec3 pixel_delta_u;
    Vec3 pixel_delta_v;
    Vec3 defocus_disk_u;
    Vec3 defocus_disk_v;
};

// ---------------------------------------------
// Scene data
// ---------------------------------------------

enum MaterialType : int
{
    MAT_LAMBERTIAN = 0,
    MAT_METAL = 1,
    MAT_DIELECTRIC = 2
};

struct Material
{
    int type;      // MaterialType
    Vec3 albedo;   // For lambertian/metal
    float fuzz;    // For metal
    float ref_idx; // For dielectric
};

struct Sphere
{
    Vec3 center;
    float radius;
    int material_index;
};

struct HitRecord
{
    Vec3 p;
    Vec3 normal;
    float t;
    bool front_face;
    int material_index;
};

__device__ inline void set_face_normal(const Ray &r, const Vec3 &outward_normal, HitRecord &rec)
{
    rec.front_face = dot(r.dir, outward_normal) < 0.0f;
    rec.normal = rec.front_face ? outward_normal : -outward_normal;
}

__device__ inline bool hit_sphere(const Sphere &s, const Ray &r, float tmin, float tmax, HitRecord &rec)
{
    Vec3 oc = s.center - r.orig;
    float a = r.dir.length_squared();
    float h = dot(r.dir, oc);
    float c = oc.length_squared() - s.radius * s.radius;
    float disc = h * h - a * c;
    if (disc < 0.0f)
        return false;
    float sqrtd = sqrtf(disc);
    float root = (h - sqrtd) / a;
    if (root <= tmin || root >= tmax)
    {
        root = (h + sqrtd) / a;
        if (root <= tmin || root >= tmax)
            return false;
    }
    rec.t = root;
    rec.p = r.at(rec.t);
    Vec3 outward_normal = (rec.p - s.center) / s.radius;
    set_face_normal(r, outward_normal, rec);
    rec.material_index = s.material_index;
    return true;
}

__device__ inline bool hit_world(const Sphere *spheres, int num_spheres, const Ray &r, float tmin, float tmax, HitRecord &rec)
{
    HitRecord tmp{};
    bool hit_any = false;
    float closest = tmax;
    for (int i = 0; i < num_spheres; i++)
    {
        if (hit_sphere(spheres[i], r, tmin, closest, tmp))
        {
            hit_any = true;
            closest = tmp.t;
            rec = tmp;
        }
    }
    return hit_any;
}

__device__ inline float schlick_reflectance(float cosine, float ref_idx)
{
    float r0 = (1.0f - ref_idx) / (1.0f + ref_idx);
    r0 = r0 * r0;
    float omc = (1.0f - cosine);
    float omc2 = omc * omc;
    float omc5 = omc2 * omc2 * omc;
    return r0 + (1.0f - r0) * omc5;
}

__device__ inline bool scatter(const Material &m, RNG &rng, const Ray &r_in, const HitRecord &rec, Vec3 &attenuation, Ray &scattered)
{
    if (m.type == MAT_LAMBERTIAN)
    {
        Vec3 scatter_direction = rec.normal + random_unit_vector(rng);
        if (scatter_direction.near_zero())
            scatter_direction = rec.normal;
        scattered = Ray(rec.p, scatter_direction);
        attenuation = m.albedo;
        return true;
    }
    else if (m.type == MAT_METAL)
    {
        Vec3 reflected = unit_vector(reflect(r_in.dir, rec.normal));
        Vec3 fuzz_vec = m.fuzz * random_unit_vector(rng);
        scattered = Ray(rec.p, reflected + fuzz_vec);
        attenuation = m.albedo;
        return dot(scattered.dir, rec.normal) > 0.0f;
    }
    else
    {
        attenuation = Vec3(1.0f, 1.0f, 1.0f);
        float ri = rec.front_face ? (1.0f / m.ref_idx) : m.ref_idx;
        Vec3 unit_direction = unit_vector(r_in.dir);
        float cos_theta = fminf(dot(-unit_direction, rec.normal), 1.0f);
        float sin_theta = sqrtf(1.0f - cos_theta * cos_theta);
        bool cannot_refract = ri * sin_theta > 1.0f;
        Vec3 direction;
        if (cannot_refract || schlick_reflectance(cos_theta, ri) > randf(rng))
        {
            direction = reflect(unit_direction, rec.normal);
        }
        else
        {
            direction = refract(unit_direction, rec.normal, ri);
        }
        scattered = Ray(rec.p, direction);
        return true;
    }
}

__device__ inline Vec3 ray_color(RNG &rng, const Ray &r0, const Sphere *spheres, int num_spheres, const Material *materials, int max_depth)
{
    Ray r = r0;
    Vec3 cur_attenuation = Vec3(1.0f, 1.0f, 1.0f);
    for (int depth = 0; depth < max_depth; depth++)
    {
        HitRecord rec{};
        if (hit_world(spheres, num_spheres, r, 0.001f, 1e30f, rec))
        {
            Ray scattered;
            Vec3 attenuation;
            const Material &m = materials[rec.material_index];
            if (scatter(m, rng, r, rec, attenuation, scattered))
            {
                cur_attenuation = cur_attenuation * attenuation;
                r = scattered;
            }
            else
            {
                return Vec3(0, 0, 0);
            }
        }
        else
        {
            Vec3 unit_d = unit_vector(r.dir);
            float a = 0.5f * (unit_d.y + 1.0f);
            Vec3 bg = (1.0f - a) * Vec3(1.0f, 1.0f, 1.0f) + a * Vec3(0.5f, 0.7f, 1.0f);
            return cur_attenuation * bg;
        }
    }
    return Vec3(0, 0, 0);
}

static constexpr float PI_F = 3.14159265358979323846f;

__device__ inline Ray get_ray(const CameraData &cam, int i, int j, RNG &rng)
{
    float du = randf(rng) - 0.5f;
    float dv = randf(rng) - 0.5f;
    Vec3 pixel_sample = cam.pixel00_loc + ((i + du) * cam.pixel_delta_u) + ((j + dv) * cam.pixel_delta_v);
    Vec3 ray_origin = cam.center;
    if (cam.defocus_angle > 0.0f)
    {
        float radius = tanf((cam.defocus_angle * PI_F / 180.0f) * 0.5f) * cam.focus_dist;
        Vec3 p = random_in_unit_disk(rng) * radius;
        Vec3 offset = p.x * cam.defocus_disk_u + p.y * cam.defocus_disk_v;
        ray_origin = cam.center + offset;
    }
    Vec3 ray_dir = pixel_sample - ray_origin;
    return Ray(ray_origin, ray_dir);
}

// ---------------------------------------------
// Kernel
// ---------------------------------------------

__global__ void render_kernel(Vec3 *framebuffer,
                              CameraData cam,
                              const Sphere *spheres, int num_spheres,
                              const Material *materials,
                              unsigned int seed_base)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= cam.image_width || y >= cam.image_height)
        return;
    int idx = y * cam.image_width + x;

    RNG rng{seed_base ^ (idx * 9781u + 1u)};
    Vec3 col(0, 0, 0);
    for (int s = 0; s < cam.samples_per_pixel; s++)
    {
        Ray r = get_ray(cam, x, y, rng);
        col += ray_color(rng, r, spheres, num_spheres, materials, cam.max_depth);
    }
    col /= (float)cam.samples_per_pixel;
    // gamma 2.0
    col.x = col.x > 0.0f ? sqrtf(col.x) : 0.0f;
    col.y = col.y > 0.0f ? sqrtf(col.y) : 0.0f;
    col.z = col.z > 0.0f ? sqrtf(col.z) : 0.0f;
    framebuffer[idx] = col;
}

// ---------------------------------------------
// Host utilities
// ---------------------------------------------

static inline float to_radians(float deg) { return deg * PI_F / 180.0f; }

struct HostCamera
{
    // Inputs
    double aspect_ratio = 16.0 / 9.0;
    int image_width = 800;
    int samples_per_pixel = 50;
    int max_depth = 50;
    double vfov = 20.0; // degrees
    Vec3 lookfrom = Vec3(13, 2, 3);
    Vec3 lookat = Vec3(0, 0, 0);
    Vec3 vup = Vec3(0, 1, 0);
    double defocus_angle = 0.6; // degrees
    double focus_dist = 10.0;

    // Derived
    CameraData to_device() const
    {
        CameraData cam{};
        cam.image_width = image_width;
        cam.image_height = (int)std::max(1, (int)std::lrint((double)image_width / aspect_ratio));
        cam.samples_per_pixel = samples_per_pixel;
        cam.max_depth = max_depth;
        cam.defocus_angle = (float)defocus_angle;
        cam.focus_dist = (float)focus_dist;

        Vec3 center = lookfrom;
        cam.center = center;

        float theta = to_radians((float)vfov);
        float h = tanf(theta * 0.5f);
        float viewport_height = 2.0f * h * (float)focus_dist;
        float viewport_width = viewport_height * (float)((double)image_width / cam.image_height);

        Vec3 w = unit_vector(lookfrom - lookat);
        Vec3 u = unit_vector(cross(vup, w));
        Vec3 v = cross(w, u);

        Vec3 viewport_u = viewport_width * u;
        Vec3 viewport_v = -viewport_height * v;

        Vec3 pixel_delta_u = viewport_u / (float)image_width;
        Vec3 pixel_delta_v = viewport_v / (float)cam.image_height;

        Vec3 viewport_upper_left = center - (float)focus_dist * w - viewport_u * 0.5f - viewport_v * 0.5f;
        Vec3 pixel00_loc = viewport_upper_left + 0.5f * (pixel_delta_u + pixel_delta_v);

        float defocus_radius = (float)focus_dist * tanf(to_radians((float)defocus_angle * 0.5f));
        Vec3 defocus_disk_u = u * defocus_radius;
        Vec3 defocus_disk_v = v * defocus_radius;

        cam.pixel00_loc = pixel00_loc;
        cam.pixel_delta_u = pixel_delta_u;
        cam.pixel_delta_v = pixel_delta_v;
        cam.defocus_disk_u = defocus_disk_u;
        cam.defocus_disk_v = defocus_disk_v;
        return cam;
    }
};

static void write_ppm(const std::string &path, int width, int height, const std::vector<Vec3> &fb)
{
    std::ofstream out(path);
    if (!out.is_open())
    {
        std::cerr << "Could not open output file: " << path << "\n";
        return;
    }
    out << "P3\n"
        << width << ' ' << height << "\n255\n";
    auto clamp01 = [](float x)
    { return x < 0 ? 0.0f : (x > 0.999f ? 0.999f : x); };
    for (int j = 0; j < height; j++)
    {
        for (int i = 0; i < width; i++)
        {
            const Vec3 &c = fb[j * width + i];
            int r = (int)(256 * clamp01(c.x));
            int g = (int)(256 * clamp01(c.y));
            int b = (int)(256 * clamp01(c.z));
            out << r << ' ' << g << ' ' << b << '\n';
        }
    }
}

// ---------------------------------------------
// CLI parsing compatible with existing C++
// ---------------------------------------------

int main(int argc, char **argv)
{
    std::string sphere_data_path = "sphere_data.txt";
    std::string output_ppm_path = "cuda_spheres.ppm";
    int cores = 0; // ignored but accepted

    for (int i = 1; i < argc; i++)
    {
        std::string arg(argv[i]);
        if (arg == "--path" && i + 1 < argc)
        {
            sphere_data_path = argv[++i];
        }
        else if (arg == "--output" && i + 1 < argc)
        {
            output_ppm_path = argv[++i];
        }
        else if (arg == "--cores" && i + 1 < argc)
        {
            cores = std::atoi(argv[++i]);
            (void)cores;
        }
        else if (arg == "--help" || arg == "-h")
        {
            std::cout << "Usage: " << argv[0] << " [--path <sphere_data_path>] [--output <output_ppm_path>] [--cores <num_cores>]\n";
            return 0;
        }
        else
        {
            std::cerr << "Error: Unknown argument: " << arg << "\n";
            return 1;
        }
    }

    HostCamera hostCam;

    // Read scene file
    std::ifstream infile(sphere_data_path);
    if (!infile.is_open())
    {
        std::cerr << "Could not open file: " << sphere_data_path << "\n";
        return 1;
    }

    std::vector<Sphere> spheres_host;
    std::vector<Material> materials_host;

    std::string line;
    while (std::getline(infile, line))
    {
        if (line.empty() || line[0] == '#')
            continue;
        std::istringstream iss(line);
        std::string first;
        iss >> first;
        if (first == "c")
        {
            std::string param;
            iss >> param;
            if (param == "ratio")
            {
                double w, h;
                if (iss >> w >> h)
                    hostCam.aspect_ratio = w / h;
            }
            else if (param == "width")
            {
                int w;
                if (iss >> w)
                    hostCam.image_width = w;
            }
            else if (param == "samplesPerPixel")
            {
                int s;
                if (iss >> s)
                    hostCam.samples_per_pixel = s;
            }
            else if (param == "maxDepth")
            {
                int d;
                if (iss >> d)
                    hostCam.max_depth = d;
            }
            else if (param == "vfov")
            {
                double v;
                if (iss >> v)
                    hostCam.vfov = v;
            }
            else if (param == "lookFrom")
            {
                double x, y, z;
                if (iss >> x >> y >> z)
                    hostCam.lookfrom = Vec3((float)x, (float)y, (float)z);
            }
            else if (param == "lookAt")
            {
                double x, y, z;
                if (iss >> x >> y >> z)
                    hostCam.lookat = Vec3((float)x, (float)y, (float)z);
            }
            else if (param == "vup")
            {
                double x, y, z;
                if (iss >> x >> y >> z)
                    hostCam.vup = Vec3((float)x, (float)y, (float)z);
            }
            else if (param == "defocusAngle")
            {
                double a;
                if (iss >> a)
                    hostCam.defocus_angle = a;
            }
            else if (param == "focusDist")
            {
                double d;
                if (iss >> d)
                    hostCam.focus_dist = d;
            }
            continue;
        }
        // Else treat as sphere
        iss.clear();
        iss.seekg(0);
        double x, y, z, radius;
        std::string mtype;
        if (!(iss >> x >> y >> z >> radius >> mtype))
            continue;
        Material m{};
        if (mtype == "lambertian")
        {
            double r, g, b;
            if (!(iss >> r >> g >> b))
                continue;
            m.type = MAT_LAMBERTIAN;
            m.albedo = Vec3((float)r, (float)g, (float)b);
            m.fuzz = 0;
            m.ref_idx = 1.0f;
        }
        else if (mtype == "metal")
        {
            double r, g, b, f;
            if (!(iss >> r >> g >> b >> f))
                continue;
            m.type = MAT_METAL;
            m.albedo = Vec3((float)r, (float)g, (float)b);
            m.fuzz = (float)f;
            m.ref_idx = 1.0f;
        }
        else if (mtype == "dielectric")
        {
            double ri;
            if (!(iss >> ri))
                continue;
            m.type = MAT_DIELECTRIC;
            m.albedo = Vec3(1, 1, 1);
            m.fuzz = 0;
            m.ref_idx = (float)ri;
        }
        else
        {
            continue;
        }
        int mat_index = (int)materials_host.size();
        materials_host.push_back(m);
        Sphere s{};
        s.center = Vec3((float)x, (float)y, (float)z);
        s.radius = (float)fmax(0.0, radius);
        s.material_index = mat_index;
        spheres_host.push_back(s);
    }
    infile.close();
    std::cout << "Loaded world from " << sphere_data_path << "\n";

    CameraData cam = hostCam.to_device();

    // Allocate device memory
    Vec3 *d_framebuffer = nullptr;
    Sphere *d_spheres = nullptr;
    Material *d_materials = nullptr;
    size_t fb_bytes = (size_t)cam.image_width * (size_t)cam.image_height * sizeof(Vec3);
    cudaMalloc(&d_framebuffer, fb_bytes);
    cudaMalloc(&d_spheres, spheres_host.size() * sizeof(Sphere));
    cudaMalloc(&d_materials, materials_host.size() * sizeof(Material));
    cudaMemcpy(d_spheres, spheres_host.data(), spheres_host.size() * sizeof(Sphere), cudaMemcpyHostToDevice);
    cudaMemcpy(d_materials, materials_host.data(), materials_host.size() * sizeof(Material), cudaMemcpyHostToDevice);

    // Launch kernel
    dim3 block(16, 16);
    dim3 grid((cam.image_width + block.x - 1) / block.x, (cam.image_height + block.y - 1) / block.y);
    unsigned int seed_base = 1337u;
    render_kernel<<<grid, block>>>(d_framebuffer, cam, d_spheres, (int)spheres_host.size(), d_materials, seed_base);
    cudaDeviceSynchronize();

    // Copy back
    std::vector<Vec3> framebuffer((size_t)cam.image_width * (size_t)cam.image_height);
    cudaMemcpy(framebuffer.data(), d_framebuffer, fb_bytes, cudaMemcpyDeviceToHost);

    // Write PPM
    write_ppm(output_ppm_path, cam.image_width, cam.image_height, framebuffer);
    std::cout << "Wrote: " << output_ppm_path << "\n";

    // Cleanup
    cudaFree(d_framebuffer);
    cudaFree(d_spheres);
    cudaFree(d_materials);

    return 0;
}
