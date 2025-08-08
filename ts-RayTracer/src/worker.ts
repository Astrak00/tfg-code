import { Camera } from "./camera";
import { cameraFromDTO, buildWorldFromDesc, WorldDesc, CameraConfigDTO } from "./world";
import { HittableList } from "./hittable_list";
import { Vec3 } from "./vec3";

let cam: Camera | null = null;
let world: HittableList | null = null;
let width = 0;
let height = 0;

type InitMsg = { type: "init"; cam: CameraConfigDTO; world: WorldDesc };
type RenderRowMsg = { type: "renderRow"; row: number };
type InMsg = InitMsg | RenderRowMsg;

type RowResult = { type: "row"; row: number; colors: number[] };

function ensureInit() {
  if (!cam || !world) throw new Error("Worker not initialized");
}

function handleMessage(ev: any) {
  const data = ev.data as InMsg;
  if (data.type === "init") {
    cam = cameraFromDTO(data.cam);
    cam.initialize();
    world = buildWorldFromDesc(data.world);
    width = cam.imageWidth;
    height = Math.max(1, Math.floor(cam.imageWidth / cam.aspectRatio));
    return;
  }
  if (data.type === "renderRow") {
    ensureInit();
    const row = data.row;
    const colors: number[] = new Array(width * 3);
    for (let i = 0; i < width; i++) {
      let pixelColor = new Vec3([0, 0, 0]);
      for (let s = 0; s < (cam as Camera).samplesPerPixel; s++) {
        const r = (cam as Camera).getRay(i, row);
        pixelColor = pixelColor.add((cam as Camera).rayColor(r, (cam as Camera).maxDepth, world!));
      }
      pixelColor = pixelColor.mulScalar(1.0 / (cam as Camera).samplesPerPixel);
      const idx = i * 3;
      colors[idx + 0] = pixelColor.x();
      colors[idx + 1] = pixelColor.y();
      colors[idx + 2] = pixelColor.z();
    }
    const msg: RowResult = { type: "row", row, colors };
    (globalThis as any).postMessage(msg);
  }
}

(globalThis as any).onmessage = handleMessage;


