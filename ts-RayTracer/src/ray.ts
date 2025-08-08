import { Point3, Vec3 } from "./vec3";

export class Ray {
  constructor(public readonly orig: Point3, public readonly dir: Vec3) {}

  origin(): Point3 {
    return this.orig;
  }
  direction(): Vec3 {
    return this.dir;
  }
  at(t: number): Point3 {
    return this.orig.add(this.dir.mulScalar(t));
  }
}


