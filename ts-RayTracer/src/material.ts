import { Ray } from "./ray";
import { HitRecord, Material } from "./hittable";
import { Color, Vec3, reflect, refract, unitVector, randomUnitVector } from "./vec3";

export class Lambertian implements Material {
  constructor(public albedo: Color) {}
  scatter(rIn: Ray, rec: HitRecord) {
    let scatterDirection = rec.normal.add(randomUnitVector());
    if (scatterDirection.nearZero()) scatterDirection = rec.normal;
    const scattered = new Ray(rec.p, scatterDirection);
    const attenuation = this.albedo;
    return { didScatter: true, attenuation, scattered };
  }
}

export class Metal implements Material {
  constructor(public albedo: Color, public fuzz: number) {}
  scatter(rIn: Ray, rec: HitRecord) {
    const reflected = reflect(unitVector(rIn.direction()), rec.normal);
    const fuzzClamped = Math.min(this.fuzz, 1.0);
    const fuzzVector = randomUnitVector().mulScalar(fuzzClamped);
    const scattered = new Ray(rec.p, reflected.add(fuzzVector));
    const attenuation = this.albedo;
    const didScatter = dot(scattered.direction(), rec.normal) > 0;
    return { didScatter, attenuation, scattered };
  }
}

export class Dielectric implements Material {
  constructor(public refractionIndex: number) {}
  scatter(rIn: Ray, rec: HitRecord) {
    const attenuation = new Vec3([1.0, 1.0, 1.0]);
    const refractionRatio = rec.frontFace ? 1.0 / this.refractionIndex : this.refractionIndex;
    const unitDirection = unitVector(rIn.direction());
    const cosTheta = Math.min(dot(unitDirection.neg(), rec.normal), 1.0);
    const sinTheta = Math.sqrt(1.0 - cosTheta * cosTheta);
    const cannotRefract = refractionRatio * sinTheta > 1.0;
    let direction: Vec3;
    if (cannotRefract || this.reflectance(cosTheta, refractionRatio) > Math.random()) {
      direction = reflect(unitDirection, rec.normal);
    } else {
      direction = refract(unitDirection, rec.normal, refractionRatio);
    }
    const scattered = new Ray(rec.p, direction);
    return { didScatter: true, attenuation, scattered };
  }
  private reflectance(cosine: number, refIdx: number): number {
    let r0 = (1.0 - refIdx) / (1.0 + refIdx);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * Math.pow(1.0 - cosine, 5);
  }
}

// local util to avoid cycle
function dot(u: Vec3, v: Vec3): number {
  return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
}


