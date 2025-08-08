import { randomDoubleRange } from "./rtweekend";

export class Vec3 {
  constructor(public readonly e: [number, number, number]) {}

  static of(x: number, y: number, z: number): Vec3 {
    return new Vec3([x, y, z]);
  }

  x(): number {
    return this.e[0];
  }
  y(): number {
    return this.e[1];
  }
  z(): number {
    return this.e[2];
  }

  neg(): Vec3 {
    return Vec3.of(-this.e[0], -this.e[1], -this.e[2]);
  }

  at(i: number): number {
    return this.e[i];
  }

  add(o: Vec3): Vec3 {
    return Vec3.of(this.e[0] + o.e[0], this.e[1] + o.e[1], this.e[2] + o.e[2]);
  }

  sub(o: Vec3): Vec3 {
    return Vec3.of(this.e[0] - o.e[0], this.e[1] - o.e[1], this.e[2] - o.e[2]);
  }

  mul(o: Vec3): Vec3 {
    return Vec3.of(this.e[0] * o.e[0], this.e[1] * o.e[1], this.e[2] * o.e[2]);
  }

  mulScalar(t: number): Vec3 {
    return Vec3.of(t * this.e[0], t * this.e[1], t * this.e[2]);
  }

  divScalar(t: number): Vec3 {
    return this.mulScalar(1 / t);
  }

  lengthSquared(): number {
    return this.e[0] * this.e[0] + this.e[1] * this.e[1] + this.e[2] * this.e[2];
  }

  length(): number {
    return Math.sqrt(this.lengthSquared());
  }

  nearZero(): boolean {
    const s = 1e-8;
    return Math.abs(this.e[0]) < s && Math.abs(this.e[1]) < s && Math.abs(this.e[2]) < s;
  }

  static random(): Vec3 {
    return Vec3.of(Math.random(), Math.random(), Math.random());
  }

  static randomRange(min: number, max: number): Vec3 {
    return Vec3.of(
      randomDoubleRange(min, max),
      randomDoubleRange(min, max),
      randomDoubleRange(min, max)
    );
  }
}

export type Point3 = Vec3;
export type Color = Vec3;

export function dot(u: Vec3, v: Vec3): number {
  return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
}

export function cross(u: Vec3, v: Vec3): Vec3 {
  return Vec3.of(
    u.e[1] * v.e[2] - u.e[2] * v.e[1],
    u.e[2] * v.e[0] - u.e[0] * v.e[2],
    u.e[0] * v.e[1] - u.e[1] * v.e[0]
  );
}

export function unitVector(v: Vec3): Vec3 {
  return v.divScalar(v.length());
}

export function randomInUnitDisk(): Vec3 {
  for (;;) {
    const p = Vec3.of(2 * Math.random() - 1, 2 * Math.random() - 1, 0);
    if (p.lengthSquared() < 1) return p;
  }
}

export function randomUnitVector(): Vec3 {
  for (;;) {
    const p = Vec3.randomRange(-1, 1);
    const lenSq = p.lengthSquared();
    if (1e-160 < lenSq && lenSq <= 1.0) return p.divScalar(Math.sqrt(lenSq));
  }
}

export function randomOnHemisphere(normal: Vec3): Vec3 {
  const onUnitSphere = randomUnitVector();
  if (dot(onUnitSphere, normal) > 0.0) return onUnitSphere;
  return onUnitSphere.neg();
}

export function reflect(v: Vec3, n: Vec3): Vec3 {
  return v.sub(n.mulScalar(2 * dot(v, n)));
}

export function refract(uv: Vec3, n: Vec3, etaiOverEtat: number): Vec3 {
  const cosTheta = Math.min(dot(uv.neg(), n), 1.0);
  const rOutPerp = uv.add(n.mulScalar(cosTheta)).mulScalar(etaiOverEtat);
  const rOutParallel = n.mulScalar(-Math.sqrt(Math.abs(1.0 - rOutPerp.lengthSquared())));
  return rOutPerp.add(rOutParallel);
}


