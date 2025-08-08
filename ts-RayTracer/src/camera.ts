import { degreesToRadians } from "./rtweekend";
import { Image } from "./image";
import { Hittable, HitRecord } from "./hittable";
import { Interval } from "./interval";
import { Ray } from "./ray";
import { Color, Point3, Vec3, cross, randomInUnitDisk, unitVector } from "./vec3";

export class Camera {
  // Public config
  aspectRatio = 1.0;
  imageWidth = 100;
  samplesPerPixel = 10;
  maxDepth = 10;
  vfov = 90;
  lookFrom: Point3 = new Vec3([0, 0, 0]);
  lookAt: Point3 = new Vec3([0, 0, -1]);
  vup: Vec3 = new Vec3([0, 1, 0]);
  defocusAngle = 0;
  focusDist = 10;

  // Private
  private imageHeight = 0;
  private pixelSamplesScale = 1.0;
  private center: Point3 = this.lookFrom;
  private pixel00Loc: Point3 = this.lookFrom;
  private pixelDeltaU: Vec3 = new Vec3([0, 0, 0]);
  private pixelDeltaV: Vec3 = new Vec3([0, 0, 0]);
  private u: Vec3 = new Vec3([0, 0, 0]);
  private v: Vec3 = new Vec3([0, 0, 0]);
  private w: Vec3 = new Vec3([0, 0, 0]);
  private defocusDiskU: Vec3 = new Vec3([0, 0, 0]);
  private defocusDiskV: Vec3 = new Vec3([0, 0, 0]);

  initialize() {
    this.imageHeight = Math.floor(this.imageWidth / this.aspectRatio);
    if (this.imageHeight < 1) this.imageHeight = 1;
    this.pixelSamplesScale = 1.0 / this.samplesPerPixel;
    this.center = this.lookFrom;

    const theta = degreesToRadians(this.vfov);
    const h = Math.tan(theta / 2);
    const viewportHeight = 2 * h * this.focusDist;
    const viewportWidth = viewportHeight * (this.imageWidth / this.imageHeight);

    this.w = unitVector(this.lookFrom.sub(this.lookAt));
    this.u = unitVector(cross(this.vup, this.w));
    this.v = cross(this.w, this.u);

    const viewportU = this.u.mulScalar(viewportWidth);
    const viewportV = this.v.mulScalar(-viewportHeight);

    this.pixelDeltaU = viewportU.divScalar(this.imageWidth);
    this.pixelDeltaV = viewportV.divScalar(this.imageHeight);

    const viewportUpperLeft = this.center
      .sub(this.w.mulScalar(this.focusDist))
      .sub(viewportU.divScalar(2))
      .sub(viewportV.divScalar(2));
    this.pixel00Loc = viewportUpperLeft.add(this.pixelDeltaU.add(this.pixelDeltaV).mulScalar(0.5));

    const defocusRadius = this.focusDist * Math.tan(degreesToRadians(this.defocusAngle / 2));
    this.defocusDiskU = this.u.mulScalar(defocusRadius);
    this.defocusDiskV = this.v.mulScalar(defocusRadius);
  }

  private sampleSquare(): Vec3 {
    return new Vec3([Math.random() - 0.5, Math.random() - 0.5, 0]);
  }

  private defocusDiskSample(): Point3 {
    const p = randomInUnitDisk();
    return this.center
      .add(this.defocusDiskU.mulScalar(p.e[0]))
      .add(this.defocusDiskV.mulScalar(p.e[1]));
  }

  getRay(i: number, j: number): Ray {
    const offset = this.sampleSquare();
    const pixelSample = this.pixel00Loc
      .add(this.pixelDeltaU.mulScalar(i + offset.x()))
      .add(this.pixelDeltaV.mulScalar(j + offset.y()));
    let rayOrigin = this.center;
    if (this.defocusAngle > 0) {
      rayOrigin = this.defocusDiskSample();
    }
    const rayDirection = pixelSample.sub(rayOrigin);
    return new Ray(rayOrigin, rayDirection);
  }

  rayColor(r: Ray, depth: number, world: Hittable): Color {
    if (depth <= 0) return new Vec3([0, 0, 0]);
    const rec = new HitRecord();
    if (world.hit(r, new Interval(0.001, Number.POSITIVE_INFINITY), rec)) {
      const { didScatter, attenuation, scattered } = rec.mat.scatter(r, rec);
      if (didScatter) {
        return attenuation.mul(this.rayColor(scattered, depth - 1, world));
      }
      return new Vec3([0, 0, 0]);
    }
    const unitDirection = unitVector(r.direction());
    const a = 0.5 * (unitDirection.y() + 1.0);
    const white = new Vec3([1.0, 1.0, 1.0]);
    const blue = new Vec3([0.5, 0.7, 1.0]);
    return white.mulScalar(1.0 - a).add(blue.mulScalar(a));
  }

  renderSync(world: Hittable): string {
    this.initialize();
    const img = new Image(this.imageWidth, this.imageHeight);
    for (let j = 0; j < this.imageHeight; j++) {
      process.stdout.write(`\rScanlines remaining: ${this.imageHeight - j} `);
      for (let i = 0; i < this.imageWidth; i++) {
        let pixelColor = new Vec3([0, 0, 0]);
        for (let s = 0; s < this.samplesPerPixel; s++) {
          const r = this.getRay(i, j);
          pixelColor = pixelColor.add(this.rayColor(r, this.maxDepth, world));
        }
        img.setPixel(i, j, pixelColor.mulScalar(this.pixelSamplesScale));
      }
    }
    process.stdout.write(`\rScanlines remaining: 0 `);
    return img.toPPM();
  }
}


