import { Material, HitRecord } from './hittable';
import { Ray } from './ray';
import { Color, Vec3, add, mulScalar, randomUnitVector, reflect, refract, unitVector } from './vec3';
import { randomDouble } from './rtweekend';

export class Lambertian implements Material {
  constructor(private albedo: Color) {}

  scatter(rIn: Ray, rec: HitRecord) {
    let scatterDirection = add(rec.normal, randomUnitVector());
    if (scatterDirection.nearZero()) scatterDirection = rec.normal;
    const scattered = new Ray(rec.p, scatterDirection);
    const attenuation = this.albedo;
    return { attenuation, scattered };
  }
}

export class Metal implements Material {
  private fuzz: number;
  constructor(private albedo: Color, fuzz: number) {
    this.fuzz = fuzz < 1 ? fuzz : 1;
  }

  scatter(rIn: Ray, rec: HitRecord) {
    let reflected = reflect(rIn.direction(), rec.normal);
    reflected = add(unitVector(reflected), mulScalar(this.fuzz, randomUnitVector()));
    const scattered = new Ray(rec.p, reflected);
    const attenuation = this.albedo;
    if (dot(scattered.direction(), rec.normal) > 0) return { attenuation, scattered };
    return null;
  }
}

export class Dielectric implements Material {
  constructor(private refractionIndex: number) {}

  scatter(rIn: Ray, rec: HitRecord) {
    const attenuation = new Vec3(1.0, 1.0, 1.0);
    const ri = rec.frontFace ? 1.0 / this.refractionIndex : this.refractionIndex;

    const unitDirection = unitVector(rIn.direction());
    const cosTheta = Math.min(dot(mulScalar(-1, unitDirection), rec.normal), 1.0);
    const sinTheta = Math.sqrt(1.0 - cosTheta * cosTheta);

    const cannotRefract = ri * sinTheta > 1.0;
    let direction: Vec3;
    if (cannotRefract || reflectance(cosTheta, ri) > randomDouble()) {
      direction = reflect(unitDirection, rec.normal);
    } else {
      direction = refract(unitDirection, rec.normal, ri);
    }
    const scattered = new Ray(rec.p, direction);
    return { attenuation, scattered };
  }
}

function reflectance(cosine: number, refractionIndex: number): number {
  const r0 = (1 - refractionIndex) / (1 + refractionIndex);
  const r0sq = r0 * r0;
  const oneMinusCos = 1.0 - cosine;
  const oneMinusCos2 = oneMinusCos * oneMinusCos;
  const oneMinusCos5 = oneMinusCos2 * oneMinusCos2 * oneMinusCos;
  return r0sq + (1 - r0sq) * oneMinusCos5;
}

function dot(u: Vec3, v: Vec3): number { return u.x() * v.x() + u.y() * v.y() + u.z() * v.z(); }


