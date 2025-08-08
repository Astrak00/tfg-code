#!/usr/bin/env bun
import { promises as fs } from "fs";
import os from "os";
import { Camera } from "./camera";
import { HittableList } from "./hittable_list";
import { createWorldFromFile, randomSceneAndSave, describeWorld } from "./world";
import { Image } from "./image";
import { Vec3 } from "./vec3";

function parseArgs(argv: string[]) {
  // Support flags: --path <file>, --output <file>, --cores <n>
  const args: Record<string, string | number | boolean> = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--path" || a === "--output" || a === "--cores") {
      const v = argv[i + 1];
      i++;
      if (a === "--cores") args["cores"] = Number(v);
      else args[a.slice(2)] = v;
    } else if (a.startsWith("--")) {
      args[a.slice(2)] = true;
    }
  }
  return args as { path?: string; output?: string; cores?: number };
}

async function ensureWorld(path: string): Promise<{ world: HittableList; cam: Camera }>{
  try {
    await fs.access(path);
    return await createWorldFromFile(path);
  } catch {
    console.log(`File ${path} not found. Generating random scene instead.`);
    await randomSceneAndSave(path);
    return await createWorldFromFile(path);
  }
}

async function main() {
  const { path = "sphere_data.txt", output = "", cores = 0 } = parseArgs(process.argv.slice(2));
  const numThreads = cores === 0 ? os.cpus()?.length ?? 1 : cores;

  const { world, cam } = await ensureWorld(path);
  // If camera file lines did not set defaults, mirror Go defaults
  if (cam.aspectRatio === 1.0 && cam.imageWidth === 100) {
    cam.aspectRatio = 16 / 9;
    cam.imageWidth = 1200;
    cam.samplesPerPixel = 10;
    cam.maxDepth = 10;
    cam.vfov = 20;
    cam.lookFrom = new (await import("./vec3")).Vec3([13, 2, 3]);
    cam.lookAt = new (await import("./vec3")).Vec3([0, 0, 0]);
    cam.vup = new (await import("./vec3")).Vec3([0, 1, 0]);
    cam.defocusAngle = 0.6;
    cam.focusDist = 10;
  }

  const threads = Math.max(1, (numThreads as number) | 0);
  console.log("Cores:", threads);

  let data = "";
  if (threads === 1) {
    data = cam.renderSync(world);
  } else {
    // Multi-thread using Bun Workers
    const width = cam.imageWidth;
    const height = Math.max(1, Math.floor(cam.imageWidth / cam.aspectRatio));
    const worldDesc = describeWorld(world);
    const camDTO = {
      aspectRatio: cam.aspectRatio,
      imageWidth: cam.imageWidth,
      samplesPerPixel: cam.samplesPerPixel,
      maxDepth: cam.maxDepth,
      vfov: cam.vfov,
      lookFrom: [cam.lookFrom.x(), cam.lookFrom.y(), cam.lookFrom.z()] as [number, number, number],
      lookAt: [cam.lookAt.x(), cam.lookAt.y(), cam.lookAt.z()] as [number, number, number],
      vup: [cam.vup.x(), cam.vup.y(), cam.vup.z()] as [number, number, number],
      defocusAngle: cam.defocusAngle,
      focusDist: cam.focusDist,
    };

    const image = new Image(width, height);
    const totalRows = height;
    let nextRow = 0;
    let linesRemaining = height;

    const WorkerCtor: any = (globalThis as any).Worker;
    const mkWorker = () => new WorkerCtor(new URL("./worker.js", import.meta.url), { type: "module" });
    const workers = Array.from({ length: threads }, () => mkWorker());

    await Promise.all(
      workers.map(
        (w) =>
          new Promise<void>((resolve) => {
            (w as any).onmessage = (ev: MessageEvent) => {
              const msg: any = ev.data;
              if (msg?.type === "row") {
                const row: number = msg.row;
                const colors: number[] = msg.colors;
                for (let i = 0; i < width; i++) {
                  const idx = i * 3;
                  const color = new Vec3([colors[idx + 0], colors[idx + 1], colors[idx + 2]]);
                  image.setPixel(i, row, color);
                }
                if (row % 1 === 0) {
                  linesRemaining--;
                  process.stdout.write(`\rScanlines remaining: ${linesRemaining} `);
                }
                if (nextRow < totalRows) {
                  (w as any).postMessage({ type: "renderRow", row: nextRow++ });
                } else {
                  (w as any).onmessage = null;
                  (w as any).terminate?.();
                  resolve();
                }
                return;
              }
            };
            (w as any).postMessage({ type: "init", cam: camDTO, world: worldDesc });
            (w as any).postMessage({ type: "renderRow", row: nextRow++ });
          })
      )
    );
    process.stdout.write(`\rScanlines remaining: 0 `);
    data = image.toPPM();
  }

  if (output && output.length > 0) {
    await fs.writeFile(output, data, "utf8");
  } else {
    process.stdout.write(data);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});


