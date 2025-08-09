#include <metal_stdlib>
using namespace metal;

struct CameraParams {
    float aspectRatio;
    uint imageWidth;
    uint samplesPerPixel;
    uint maxDepth;
    float vfov;
    float defocusAngle;
    float focusDist;
    float padding;
    float3 lookFrom;
    float3 lookAt;
    float3 vup;
};

struct MaterialGPU {
    uint type;
    uint pad0, pad1, pad2;
    float3 albedo;
    float fuzz;
    float ir;
    float pad3;
};

struct Sphere {
    float3 center;
    float radius;
    uint materialIndex;
    float3 pad;
};

struct Ray { float3 origin; float3 dir; };

struct HitRecord {
    float t;
    float3 p;
    float3 normal;
    bool frontFace;
    uint materialIndex;
};

inline float3 ray_at(Ray r, float t) { return r.origin + t * r.dir; }
inline float3 unit_vector(float3 v) { return normalize(v); }
inline float3 reflect_vec(float3 v, float3 n) { return v - 2.0f * dot(v, n) * n; }

float3 refract_vec(float3 uv, float3 n, float etai_over_etat) {
    float cos_theta = fmin(dot(-uv, n), 1.0);
    float3 r_out_perp = etai_over_etat * (uv + cos_theta * n);
    float3 r_out_parallel = -sqrt(fabs(1.0 - dot(r_out_perp, r_out_perp))) * n;
    return r_out_perp + r_out_parallel;
}

float schlick(float cosine, float ref_idx) {
    float r0 = (1.0 - ref_idx) / (1.0 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * pow((1.0 - cosine), 5.0);
}

bool sphere_hit(const Sphere s, Ray r, float tMin, float tMax, thread HitRecord &rec) {
    float3 oc = r.origin - s.center;
    float a = dot(r.dir, r.dir);
    float half_b = dot(oc, r.dir);
    float c = dot(oc, oc) - s.radius * s.radius;
    float discriminant = half_b * half_b - a * c;
    if (discriminant < 0.0) return false;
    float sqrtd = sqrt(discriminant);
    float root = (-half_b - sqrtd) / a;
    if (root < tMin || tMax < root) {
        root = (-half_b + sqrtd) / a;
        if (root < tMin || tMax < root) return false;
    }
    rec.t = root;
    rec.p = ray_at(r, rec.t);
    float3 outward = (rec.p - s.center) / s.radius;
    rec.frontFace = dot(r.dir, outward) < 0.0;
    rec.normal = rec.frontFace ? outward : -outward;
    rec.materialIndex = s.materialIndex;
    return true;
}

bool world_hit(const device Sphere *spheres, uint sphereCount, Ray r, float tMin, float tMax, thread HitRecord &rec) {
    HitRecord temp;
    bool hitAnything = false;
    float closest = tMax;
    for (uint i = 0; i < sphereCount; ++i) {
        if (sphere_hit(spheres[i], r, tMin, closest, temp)) {
            hitAnything = true;
            closest = temp.t;
            rec = temp;
        }
    }
    return hitAnything;
}

inline float randf(thread uint &state) {
    state ^= (state << 13);
    state ^= (state >> 17);
    state ^= (state << 5);
    return (float)(state & 0x00FFFFFF) / (float)0x01000000;
}

float3 random_in_unit_sphere(thread uint &state) {
    // XorShift RNG and bounded rejection sampling
    for (int attempt = 0; attempt < 32; ++attempt) {
        float3 p = float3(randf(state) * 2.0f - 1.0f, randf(state) * 2.0f - 1.0f, randf(state) * 2.0f - 1.0f);
        if (dot(p, p) < 1.0f) return p;
    }
    // Fallback to normalized random vector if rejection failed repeatedly
    float3 p = float3(randf(state) * 2.0f - 1.0f, randf(state) * 2.0f - 1.0f, randf(state) * 2.0f - 1.0f);
    return normalize(p);
}

float3 random_unit_vector(thread uint &state) {
    float3 v = random_in_unit_sphere(state);
    return normalize(v);
}

float3 random_in_unit_disk(thread uint &state) {
    for (int attempt = 0; attempt < 32; ++attempt) {
        float3 p = float3(randf(state) * 2.0f - 1.0f, randf(state) * 2.0f - 1.0f, 0.0f);
        if (dot(p, p) < 1.0f) return p;
    }
    float3 p = float3(randf(state) * 2.0f - 1.0f, randf(state) * 2.0f - 1.0f, 0.0f);
    return normalize(p);
}

float3 background_color(float3 dir) {
    float3 unit_d = normalize(dir);
    float a = 0.5f * (unit_d.y + 1.0f);
    return (1.0f - a) * float3(1.0, 1.0, 1.0) + a * float3(0.5, 0.7, 1.0);
}

float3 ray_color(Ray r, const device Sphere *spheres, uint sphereCount, const device MaterialGPU *materials, thread uint &rngState, uint maxDepth) {
    float3 attenuation = float3(1.0, 1.0, 1.0);
    for (uint depth = 0; depth < maxDepth; ++depth) {
        HitRecord rec;
        if (world_hit(spheres, sphereCount, r, 0.001f, 1e9f, rec)) {
            const device MaterialGPU &mat = materials[rec.materialIndex];
            if (mat.type == 0) { // lambertian
                float3 target = rec.p + rec.normal + random_unit_vector(rngState);
                r = Ray{rec.p, target - rec.p};
                attenuation *= mat.albedo;
            } else if (mat.type == 1) { // metal
                float3 reflected = reflect_vec(normalize(r.dir), rec.normal);
                float3 scatteredDir = reflected + mat.fuzz * random_unit_vector(rngState);
                r = Ray{rec.p, scatteredDir};
                attenuation *= mat.albedo;
                if (dot(r.dir, rec.normal) <= 0.0f) {
                    return float3(0.0);
                }
            } else { // dielectric
                float3 unit_direction = normalize(r.dir);
                float refraction_ratio = rec.frontFace ? (1.0f / mat.ir) : mat.ir;
                float cos_theta = fmin(dot(-unit_direction, rec.normal), 1.0f);
                float sin_theta = sqrt(1.0f - cos_theta*cos_theta);
                bool cannot_refract = refraction_ratio * sin_theta > 1.0f;
                float reflect_prob = schlick(cos_theta, refraction_ratio);
                float3 direction;
                if (cannot_refract || reflect_prob > randf(rngState)) {
                    direction = reflect_vec(unit_direction, rec.normal);
                } else {
                    direction = refract_vec(unit_direction, rec.normal, refraction_ratio);
                }
                r = Ray{rec.p, direction};
                // attenuation stays at (1,1,1)
            }
        } else {
            return attenuation * background_color(r.dir);
        }
    }
    return float3(0.0);
}

kernel void render_kernel(
    constant CameraParams &cam [[ buffer(0) ]],
    const device Sphere *spheres [[ buffer(1) ]],
    const device MaterialGPU *materials [[ buffer(2) ]],
    constant uint &sphereCount [[ buffer(3) ]],
    device float3 *outPixels [[ buffer(4) ]],
    constant uint &imageWidth [[ buffer(5) ]],
    constant uint &imageHeight [[ buffer(6) ]],
    constant uint &startSample [[ buffer(7) ]],
    constant uint &samplesThisDispatch [[ buffer(8) ]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= imageWidth || gid.y >= imageHeight) return;

    // Camera setup per pixel (compute viewport and basis)
    const float DEG2RAD = 3.14159265358979323846f / 180.0f;
    float theta = cam.vfov * DEG2RAD;
    float h = tan(theta / 2.0);
    float viewport_height = 2.0 * h * cam.focusDist;
    float viewport_width = viewport_height * (float(imageWidth) / float(imageHeight));

    float3 w = normalize(float3(cam.lookFrom.x, cam.lookFrom.y, cam.lookFrom.z) - float3(cam.lookAt.x, cam.lookAt.y, cam.lookAt.z));
    float3 u = normalize(cross(float3(cam.vup.x, cam.vup.y, cam.vup.z), w));
    float3 v = cross(w, u);

    float3 viewport_u = viewport_width * u;
    float3 viewport_v = -viewport_height * v;
    float3 pixel_delta_u = viewport_u / float(imageWidth);
    float3 pixel_delta_v = viewport_v / float(imageHeight);
    float3 viewport_upper_left = float3(cam.lookFrom.x, cam.lookFrom.y, cam.lookFrom.z) - cam.focusDist * w - viewport_u * 0.5 - viewport_v * 0.5;
    float3 pixel00_loc = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v);

    float defocus_radius = cam.focusDist * tan((cam.defocusAngle * 0.5f) * DEG2RAD);
    float3 defocus_disk_u = defocus_radius * u;
    float3 defocus_disk_v = defocus_radius * v;

    uint rngState = (gid.y * 9781u + gid.x * 6271u) ^ (0x12345678u + startSample * 0x9E3779B9u);

    float3 pixelColor = float3(0.0);
    for (uint s = 0; s < samplesThisDispatch; ++s) {
        // sample square [-0.5,0.5]
        float ox = randf(rngState) - 0.5f;
        float oy = randf(rngState) - 0.5f;
        float3 pixel_sample = pixel00_loc + (float(gid.x) + ox) * pixel_delta_u + (float(gid.y) + oy) * pixel_delta_v;

        float3 origin = float3(cam.lookFrom.x, cam.lookFrom.y, cam.lookFrom.z);
        if (cam.defocusAngle > 0.0f) {
            float3 p = random_in_unit_disk(rngState);
            origin = origin + p.x * defocus_disk_u + p.y * defocus_disk_v;
        }
        float3 direction = pixel_sample - origin;
        Ray r = {origin, direction};
        pixelColor += ray_color(r, spheres, sphereCount, materials, rngState, cam.maxDepth);
    }
    // Accumulate into output buffer (sum in linear space). Host will normalize.
    uint idx = gid.y * imageWidth + gid.x;
    // Avoid non-atomic RMW hazards by serializing dispatches on host; here it's a simple store-add
    outPixels[idx] = outPixels[idx] + pixelColor;
}


