import { promises as fs } from "fs";
import { Camera } from "./camera";
import { HittableList } from "./hittable_list";
import { Dielectric, Lambertian, Metal } from "./material";
import { Sphere } from "./sphere";
import { Color, Point3, Vec3 } from "./vec3";

export type MaterialDesc =
  | { type: "lambertian"; albedo: [number, number, number] }
  | { type: "metal"; albedo: [number, number, number]; fuzz: number }
  | { type: "dielectric"; refractionIndex: number };

export interface SphereDesc {
  center: [number, number, number];
  radius: number;
  material: MaterialDesc;
}

export interface WorldDesc {
  spheres: SphereDesc[];
}

export interface CameraConfigDTO {
  aspectRatio?: number;
  imageWidth?: number;
  samplesPerPixel?: number;
  maxDepth?: number;
  vfov?: number;
  lookFrom?: [number, number, number];
  lookAt?: [number, number, number];
  vup?: [number, number, number];
  defocusAngle?: number;
  focusDist?: number;
}

export function cameraFromDTO(dto: CameraConfigDTO): Camera {
  const cam = new Camera();
  if (dto.aspectRatio !== undefined) cam.aspectRatio = dto.aspectRatio;
  if (dto.imageWidth !== undefined) cam.imageWidth = dto.imageWidth;
  if (dto.samplesPerPixel !== undefined) cam.samplesPerPixel = dto.samplesPerPixel;
  if (dto.maxDepth !== undefined) cam.maxDepth = dto.maxDepth;
  if (dto.vfov !== undefined) cam.vfov = dto.vfov;
  if (dto.lookFrom) cam.lookFrom = new Vec3(dto.lookFrom);
  if (dto.lookAt) cam.lookAt = new Vec3(dto.lookAt);
  if (dto.vup) cam.vup = new Vec3(dto.vup);
  if (dto.defocusAngle !== undefined) cam.defocusAngle = dto.defocusAngle;
  if (dto.focusDist !== undefined) cam.focusDist = dto.focusDist;
  return cam;
}

export function describeWorld(world: HittableList): WorldDesc {
  const spheres: SphereDesc[] = [];
  for (const obj of world.objects) {
    if (obj instanceof Sphere) {
      const s = obj as Sphere;
      let material: MaterialDesc;
      if ((s.mat as any) instanceof Lambertian) {
        const m = s.mat as Lambertian;
        material = { type: "lambertian", albedo: [m.albedo.x(), m.albedo.y(), m.albedo.z()] };
      } else if ((s.mat as any) instanceof Metal) {
        const m = s.mat as Metal;
        material = { type: "metal", albedo: [m.albedo.x(), m.albedo.y(), m.albedo.z()], fuzz: m.fuzz };
      } else if ((s.mat as any) instanceof Dielectric) {
        const m = s.mat as Dielectric;
        material = { type: "dielectric", refractionIndex: m.refractionIndex };
      } else {
        continue;
      }
      spheres.push({ center: [s.center.x(), s.center.y(), s.center.z()], radius: s.radius, material });
    }
  }
  return { spheres };
}

export function buildWorldFromDesc(desc: WorldDesc): HittableList {
  const world = new HittableList();
  for (const s of desc.spheres) {
    let mat;
    switch (s.material.type) {
      case "lambertian":
        mat = new Lambertian(new Vec3(s.material.albedo));
        break;
      case "metal":
        mat = new Metal(new Vec3(s.material.albedo), s.material.fuzz);
        break;
      case "dielectric":
        mat = new Dielectric(s.material.refractionIndex);
        break;
    }
    world.add(new Sphere(new Vec3(s.center), s.radius, mat));
  }
  return world;
}

export async function createWorldFromFile(filepath: string): Promise<{ world: HittableList; cam: Camera }>{
  const world = new HittableList();
  const cam = new Camera();

  // Ground sphere
  const groundMaterial = new Lambertian(new Vec3([0.5, 0.5, 0.5]));
  world.add(new Sphere(new Vec3([0, -1000, 0]), 1000, groundMaterial));

  const raw = await fs.readFile(filepath, "utf8");
  const lines = raw.split(/\r?\n/);
  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    if (line.startsWith("c")) {
      checkCameraParameters(cam, line);
      continue;
    }
    const parts = line.split(/\s+/);
    if (parts.length < 5) continue;
    const x = parseFloat(parts[0]);
    const y = parseFloat(parts[1]);
    const z = parseFloat(parts[2]);
    const radius = parseFloat(parts[3]);
    if (!isFinite(x) || !isFinite(y) || !isFinite(z) || !isFinite(radius)) continue;
    const center = new Vec3([x, y, z]);
    const materialType = parts[4];
    switch (materialType) {
      case "lambertian": {
        if (parts.length >= 8) {
          const r = parseFloat(parts[5]);
          const g = parseFloat(parts[6]);
          const b = parseFloat(parts[7]);
          if ([r, g, b].every((v) => isFinite(v))) {
            const material = new Lambertian(new Vec3([r, g, b]));
            world.add(new Sphere(center, radius, material));
          }
        }
        break;
      }
      case "metal": {
        if (parts.length >= 9) {
          const r = parseFloat(parts[5]);
          const g = parseFloat(parts[6]);
          const b = parseFloat(parts[7]);
          const fuzz = parseFloat(parts[8]);
          if ([r, g, b, fuzz].every((v) => isFinite(v))) {
            const material = new Metal(new Vec3([r, g, b]), fuzz);
            world.add(new Sphere(center, radius, material));
          }
        }
        break;
      }
      case "dielectric": {
        if (parts.length >= 6) {
          const index = parseFloat(parts[5]);
          if (isFinite(index)) {
            const material = new Dielectric(index);
            world.add(new Sphere(center, radius, material));
          }
        }
        break;
      }
    }
  }

  return { world, cam };
}

function checkCameraParameters(cam: Camera, line: string) {
  const parts = line.split(/\s+/);
  switch (parts[1]) {
    case "ratio": {
      const first = parseFloat(parts[2]);
      const second = parseFloat(parts[3]);
      if (isFinite(first) && isFinite(second) && second !== 0) cam.aspectRatio = first / second;
      break;
    }
    case "width": {
      const w = parseInt(parts[2], 10);
      if (Number.isFinite(w)) cam.imageWidth = w;
      break;
    }
    case "samplesPerPixel": {
      const s = parseInt(parts[2], 10);
      if (Number.isFinite(s)) cam.samplesPerPixel = s;
      break;
    }
    case "maxDepth": {
      const d = parseInt(parts[2], 10);
      if (Number.isFinite(d)) cam.maxDepth = d;
      break;
    }
    case "vfov": {
      const vf = parseFloat(parts[2]);
      if (isFinite(vf)) cam.vfov = vf;
      break;
    }
    case "lookFrom": {
      const x = parseFloat(parts[2]);
      const y = parseFloat(parts[3]);
      const z = parseFloat(parts[4]);
      if ([x, y, z].every((v) => isFinite(v))) cam.lookFrom = new Vec3([x, y, z]);
      break;
    }
    case "lookAt": {
      const x = parseFloat(parts[2]);
      const y = parseFloat(parts[3]);
      const z = parseFloat(parts[4]);
      if ([x, y, z].every((v) => isFinite(v))) cam.lookAt = new Vec3([x, y, z]);
      break;
    }
    case "vup": {
      const x = parseFloat(parts[2]);
      const y = parseFloat(parts[3]);
      const z = parseFloat(parts[4]);
      if ([x, y, z].every((v) => isFinite(v))) cam.vup = new Vec3([x, y, z]);
      break;
    }
    case "defocusAngle": {
      const a = parseFloat(parts[2]);
      if (isFinite(a)) cam.defocusAngle = a;
      break;
    }
    case "focusDist": {
      const f = parseFloat(parts[2]);
      if (isFinite(f)) cam.focusDist = f;
      break;
    }
  }
}

export async function randomSceneAndSave(filePath: string): Promise<HittableList> {
  const world = new HittableList();
  const writer: string[] = [];
  const push = (s: string) => writer.push(s + "\n");

  const groundMaterial = new Lambertian(new Vec3([0.5, 0.5, 0.5]));
  world.add(new Sphere(new Vec3([0, -1000, 0]), 1000, groundMaterial));

  for (let a = -11; a < 11; a++) {
    for (let b = -11; b < 11; b++) {
      const chooseMat = Math.random();
      const center = new Vec3([a + 0.9 * Math.random(), 0.2, b + 0.9 * Math.random()]);
      if (center.sub(new Vec3([4, 0.2, 0])).length() > 0.9) {
        if (chooseMat < 0.8) {
          const albedo = Vec3.random().mul(Vec3.random());
          const mat = new Lambertian(albedo);
          world.add(new Sphere(center, 0.2, mat));
          push(`${center.x()} ${center.y()} ${center.z()} 0.2 lambertian ${albedo.x()} ${albedo.y()} ${albedo.z()}`);
        } else if (chooseMat < 0.95) {
          const albedo = Vec3.randomRange(0.1, 1);
          const fuzz = Math.random() * 0.5;
          const mat = new Metal(albedo, fuzz);
          world.add(new Sphere(center, 0.2, mat));
          push(`${center.x()} ${center.y()} ${center.z()} 0.2 metal ${albedo.x()} ${albedo.y()} ${albedo.z()} ${fuzz}`);
        } else {
          const mat = new Dielectric(1.5);
          world.add(new Sphere(center, 0.2, mat));
          push(`${center.x()} ${center.y()} ${center.z()} 0.2 dielectric 1.5`);
        }
      }
    }
  }

  const material1 = new Dielectric(1.5);
  world.add(new Sphere(new Vec3([0, 1, 0]), 1.0, material1));
  push(`0 1 0 1 dielectric 1.5`);

  const material2 = new Lambertian(new Vec3([0.4, 0.2, 0.1]));
  world.add(new Sphere(new Vec3([-4, 1, 0]), 1.0, material2));
  push(`-4 1 0 1 lambertian 0.4 0.2 0.1`);

  const material3 = new Metal(new Vec3([0.7, 0.6, 0.5]), 0.0);
  world.add(new Sphere(new Vec3([4, 1, 0]), 1.0, material3));
  push(`4 1 0 1 metal 0.7 0.6 0.5 0.0`);

  await fs.writeFile(filePath, writer.join(""), "utf8");
  return world;
}


