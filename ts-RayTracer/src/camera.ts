import { Hittable, HitRecord } from './hittable';
import { Image } from './image';
import { Material } from './hittable';
import { Interval } from './interval';
import { Ray } from './ray';
import {
  Color,
  Point3,
  Vec3,
  add,
  cross,
  dot,
  mulScalar,
  randomInUnitDisk,
  randomUnitVector,
  sub,
  unitVector,
} from './vec3';
import { degreesToRadians, infinity } from './rtweekend';

export class Camera {
  aspectRatio = 1.0;
  imageWidth = 100;
  samplesPerPixel = 10;
  maxDepth = 10;

  vfov = 90;
  lookfrom: Point3 = new Vec3(0, 0, 0);
  lookat: Point3 = new Vec3(0, 0, -1);
  vup: Vec3 = new Vec3(0, 1, 0);

  defocusAngle = 0; // degrees
  focusDist = 10;

  // derived
  private imageHeight!: number;
  private pixelSamplesScale!: number;
  private center!: Point3;
  private pixel00Loc!: Point3;
  private pixelDeltaU!: Vec3;
  private pixelDeltaV!: Vec3;
  private u!: Vec3; private v!: Vec3; private w!: Vec3;
  private defocusDiskU!: Vec3;
  private defocusDiskV!: Vec3;

  render(world: Hittable): Image {
    this.initialize();

    const image = new Image(this.imageWidth, this.imageHeight);

    let linesRemaining = this.imageHeight;
    for (let pixel = 0; pixel < this.imageWidth * this.imageHeight; pixel++) {
      const i = pixel % this.imageWidth;
      const j = Math.floor(pixel / this.imageWidth);

      if (i === 0) {
        process.stdout.write(`\rScanlines remaining: ${linesRemaining} `);
        linesRemaining -= 1;
      }

      let pixelColor = new Vec3(0, 0, 0);
      for (let s = 0; s < this.samplesPerPixel; s++) {
        const r = this.getRay(i, j);
        pixelColor = add(pixelColor, this.rayColor(r, this.maxDepth, world));
      }
      image.setPixel(i, j, mulScalar(this.pixelSamplesScale, pixelColor));
    }

    process.stdout.write(`\rDone.                 \n`);
    return image;
  }

  private initialize(): void {
    this.imageHeight = Math.max(1, Math.floor(this.imageWidth / this.aspectRatio));
    this.pixelSamplesScale = 1.0 / this.samplesPerPixel;
    this.center = this.lookfrom;

    const theta = degreesToRadians(this.vfov);
    const h = Math.tan(theta / 2);
    const viewportHeight = 2 * h * this.focusDist;
    const viewportWidth = viewportHeight * (this.imageWidth / this.imageHeight);

    this.w = unitVector(sub(this.lookfrom, this.lookat));
    this.u = unitVector(cross(this.vup, this.w));
    this.v = cross(this.w, this.u);

    const viewportU = mulScalar(viewportWidth, this.u);
    const viewportV = mulScalar(viewportHeight, mulScalar(-1, this.v));

    this.pixelDeltaU = mulScalar(1 / this.imageWidth, viewportU);
    this.pixelDeltaV = mulScalar(1 / this.imageHeight, viewportV);

    const viewportUpperLeft = sub(sub(sub(this.center, mulScalar(this.focusDist, this.w)), mulScalar(0.5, viewportU)), mulScalar(0.5, viewportV));
    this.pixel00Loc = add(viewportUpperLeft, mulScalar(0.5, add(this.pixelDeltaU, this.pixelDeltaV)));

    const defocusRadius = this.focusDist * Math.tan(degreesToRadians(this.defocusAngle / 2));
    this.defocusDiskU = mulScalar(defocusRadius, this.u);
    this.defocusDiskV = mulScalar(defocusRadius, this.v);
  }

  private getRay(i: number, j: number): Ray {
    const offset = this.sampleSquare();
    const pixelSample = add(this.pixel00Loc, add(mulScalar(i + offset.x(), this.pixelDeltaU), mulScalar(j + offset.y(), this.pixelDeltaV)));

    const rayOrigin = (this.defocusAngle <= 0) ? this.center : this.defocusDiskSample();
    const rayDirection = sub(pixelSample, rayOrigin);
    return new Ray(rayOrigin, rayDirection);
  }

  private sampleSquare(): Vec3 {
    return new Vec3(Math.random() - 0.5, Math.random() - 0.5, 0);
  }

  private defocusDiskSample(): Point3 {
    const p = randomInUnitDisk();
    return add(this.center, add(mulScalar(p.get(0), this.defocusDiskU), mulScalar(p.get(1), this.defocusDiskV)));
  }

  private rayColor(r: Ray, depth: number, world: Hittable): Color {
    if (depth <= 0) return new Vec3(0, 0, 0);

    const rec = new HitRecord();
    if (world.hit(r, new Interval(0.001, infinity), rec)) {
      const scattered = rec.mat.scatter(r, rec);
      if (scattered) {
        const child = this.rayColor(scattered.scattered, depth - 1, world);
        return new Vec3(
          scattered.attenuation.x() * child.x(),
          scattered.attenuation.y() * child.y(),
          scattered.attenuation.z() * child.z(),
        );
      }
      return new Vec3(0, 0, 0);
    }

    const unitDirection = unitVector(r.direction());
    const a = 0.5 * (unitDirection.y() + 1.0);
    const white = new Vec3(1.0, 1.0, 1.0);
    const sky = new Vec3(0.5, 0.7, 1.0);
    return add(mulScalar(1.0 - a, white), mulScalar(a, sky));
  }
}


