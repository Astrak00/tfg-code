import { Camera } from './camera';
import { HittableList } from './hittable_list';
import { Sphere } from './sphere';
import { Dielectric, Lambertian, Metal } from './material';
import { Point3, Vec3 } from './vec3';
import { promises as fs } from 'fs';
import * as path from 'path';

type Args = { path: string; output: string; cores?: number };

function parseArgs(argv: string[]): Args {
  let spherePath = 'sphere_data.txt';
  let outputPath = 'ts_spheres.ppm';
  let cores: number | undefined;
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--path') {
      if (i + 1 < argv.length) { spherePath = argv[++i]; }
      else { throw new Error('--path requires a value'); }
    } else if (arg === '--output') {
      if (i + 1 < argv.length) { outputPath = argv[++i]; }
      else { throw new Error('--output requires a value'); }
    } else if (arg === '--cores') {
      if (i + 1 < argv.length) {
        const c = Number(argv[++i]);
        if (!Number.isFinite(c) || c <= 0) throw new Error('--cores must be a positive integer');
        cores = c;
      } else { throw new Error('--cores requires a value'); }
    } else if (arg === '--help' || arg === '-h') {
      console.log(`Usage: node dist/main.js [--path <sphere_data_path>] [--output <output_ppm_path>] [--cores <num_cores>]`);
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  return { path: spherePath, output: outputPath, cores };
}

async function buildWorldFromFile(filePath: string, cam: Camera): Promise<HittableList> {
  const world = new HittableList();
  const file = await fs.readFile(filePath, 'utf8');
  const lines = file.split(/\r?\n/);
  for (let raw of lines) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;

    const parts = line.split(/\s+/);
    if (parts[0] === 'c') {
      const paramName = parts[1];
      const vals = parts.slice(2).map(Number);
      if (paramName === 'ratio' && vals.length >= 2) {
        cam.aspectRatio = vals[0] / vals[1];
      } else if (paramName === 'width' && vals.length >= 1) {
        cam.imageWidth = vals[0];
      } else if (paramName === 'samplesPerPixel' && vals.length >= 1) {
        cam.samplesPerPixel = vals[0];
      } else if (paramName === 'maxDepth' && vals.length >= 1) {
        cam.maxDepth = vals[0];
      } else if (paramName === 'vfov' && vals.length >= 1) {
        cam.vfov = vals[0];
      } else if (paramName === 'lookFrom' && vals.length >= 3) {
        cam.lookfrom = new Vec3(vals[0], vals[1], vals[2]);
      } else if (paramName === 'lookAt' && vals.length >= 3) {
        cam.lookat = new Vec3(vals[0], vals[1], vals[2]);
      } else if (paramName === 'vup' && vals.length >= 3) {
        cam.vup = new Vec3(vals[0], vals[1], vals[2]);
      } else if (paramName === 'defocusAngle' && vals.length >= 1) {
        cam.defocusAngle = vals[0];
      } else if (paramName === 'focusDist' && vals.length >= 1) {
        cam.focusDist = vals[0];
      }
      continue;
    }

    // sphere line: x y z radius material ...
    const x = Number(parts[0]);
    const y = Number(parts[1]);
    const z = Number(parts[2]);
    const radius = Number(parts[3]);
    const materialType = parts[4];
    let mat;
    if (materialType === 'lambertian') {
      const r = Number(parts[5]);
      const g = Number(parts[6]);
      const b = Number(parts[7]);
      mat = new Lambertian(new Vec3(r, g, b));
    } else if (materialType === 'metal') {
      const r = Number(parts[5]);
      const g = Number(parts[6]);
      const b = Number(parts[7]);
      const fuzz = Number(parts[8]);
      mat = new Metal(new Vec3(r, g, b), fuzz);
    } else if (materialType === 'dielectric') {
      const idx = Number(parts[5]);
      mat = new Dielectric(idx);
    } else {
      continue;
    }
    const center = new Vec3(x, y, z);
    world.add(new Sphere(center, radius, mat));
  }
  return world;
}

async function main() {
  try {
    const args = parseArgs(process.argv);
    const cam = new Camera();
    // defaults similar to C++ main
    cam.aspectRatio = 16 / 9;
    cam.imageWidth = 800;
    cam.samplesPerPixel = 50;
    cam.maxDepth = 50;
    cam.vfov = 20;
    cam.lookfrom = new Vec3(13, 2, 3);
    cam.lookat = new Vec3(0, 0, 0);
    cam.vup = new Vec3(0, 1, 0);
    cam.defocusAngle = 0.6;
    cam.focusDist = 10.0;

    const scenePath = path.isAbsolute(args.path) ? args.path : path.join(process.cwd(), args.path);
    const world = await buildWorldFromFile(scenePath, cam);
    console.log(`Loaded world from ${args.path}`);

    const image = cam.render(world);
    const ppm = image.toPPM();
    const outPath = path.isAbsolute(args.output) ? args.output : path.join(process.cwd(), args.output);
    await fs.writeFile(outPath, ppm, 'utf8');
    console.log(`Wrote image to ${outPath}`);
  } catch (err: any) {
    console.error(err?.message ?? String(err));
    process.exit(1);
  }
}

main();


