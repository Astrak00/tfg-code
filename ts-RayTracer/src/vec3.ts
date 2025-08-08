import { randomDouble, randomDoubleRange } from './rtweekend';

export class Vec3 {
  public e: [number, number, number];

  constructor(e0 = 0, e1 = 0, e2 = 0) {
    this.e = [e0, e1, e2];
  }

  static random(): Vec3 {
    return new Vec3(randomDouble(), randomDouble(), randomDouble());
  }

  static randomRange(min: number, max: number): Vec3 {
    return new Vec3(randomDoubleRange(min, max), randomDoubleRange(min, max), randomDoubleRange(min, max));
  }

  x(): number { return this.e[0]; }
  y(): number { return this.e[1]; }
  z(): number { return this.e[2]; }

  neg(): Vec3 { return new Vec3(-this.e[0], -this.e[1], -this.e[2]); }

  get(i: number): number { return this.e[i]; }
  set(i: number, value: number): void { this.e[i] = value; }

  addAssign(v: Vec3): Vec3 { this.e[0] += v.e[0]; this.e[1] += v.e[1]; this.e[2] += v.e[2]; return this; }
  mulAssign(t: number): Vec3 { this.e[0] *= t; this.e[1] *= t; this.e[2] *= t; return this; }
  divAssign(t: number): Vec3 { return this.mulAssign(1 / t); }

  length(): number { return Math.sqrt(this.lengthSquared()); }
  lengthSquared(): number { return this.e[0] * this.e[0] + this.e[1] * this.e[1] + this.e[2] * this.e[2]; }

  nearZero(): boolean {
    const s = 1e-8;
    return Math.abs(this.e[0]) < s && Math.abs(this.e[1]) < s && Math.abs(this.e[2]) < s;
  }
}

// Aliases
export type Point3 = Vec3;
export type Color = Vec3;

// Utility functions
export function add(u: Vec3, v: Vec3): Vec3 { return new Vec3(u.e[0] + v.e[0], u.e[1] + v.e[1], u.e[2] + v.e[2]); }
export function sub(u: Vec3, v: Vec3): Vec3 { return new Vec3(u.e[0] - v.e[0], u.e[1] - v.e[1], u.e[2] - v.e[2]); }
export function mul(u: Vec3, v: Vec3): Vec3 { return new Vec3(u.e[0] * v.e[0], u.e[1] * v.e[1], u.e[2] * v.e[2]); }
export function mulScalar(t: number, v: Vec3): Vec3 { return new Vec3(t * v.e[0], t * v.e[1], t * v.e[2]); }
export function mulVecScalar(v: Vec3, t: number): Vec3 { return mulScalar(t, v); }
export function divVecScalar(v: Vec3, t: number): Vec3 { return mulScalar(1 / t, v); }
export function dot(u: Vec3, v: Vec3): number { return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2]; }
export function cross(u: Vec3, v: Vec3): Vec3 {
  return new Vec3(
    u.e[1] * v.e[2] - u.e[2] * v.e[1],
    u.e[2] * v.e[0] - u.e[0] * v.e[2],
    u.e[0] * v.e[1] - u.e[1] * v.e[0],
  );
}
export function unitVector(v: Vec3): Vec3 { return divVecScalar(v, v.length()); }

export function randomInUnitDisk(): Vec3 {
  while (true) {
    const p = new Vec3(randomDoubleRange(-1, 1), randomDoubleRange(-1, 1), 0);
    if (p.lengthSquared() < 1) return p;
  }
}

export function randomUnitVector(): Vec3 {
  while (true) {
    const p = Vec3.randomRange(-1, 1);
    const lensq = p.lengthSquared();
    if (1e-160 < lensq && lensq <= 1.0) return divVecScalar(p, Math.sqrt(lensq));
  }
}

export function randomOnHemisphere(normal: Vec3): Vec3 {
  const onUnitSphere = randomUnitVector();
  if (dot(onUnitSphere, normal) > 0.0) return onUnitSphere;
  return onUnitSphere.neg();
}

export function reflect(v: Vec3, n: Vec3): Vec3 {
  return sub(v, mulScalar(2 * dot(v, n), n));
}

export function refract(uv: Vec3, n: Vec3, etaiOverEtat: number): Vec3 {
  const cosTheta = Math.min(dot(mulScalar(-1, uv), n), 1.0);
  const rOutPerp = mulScalar(etaiOverEtat, add(uv, mulScalar(cosTheta, n)));
  const rOutParallel = mulScalar(-Math.sqrt(Math.abs(1.0 - rOutPerp.lengthSquared())), n);
  return add(rOutPerp, rOutParallel);
}


