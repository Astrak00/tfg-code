import { Point3, Vec3, add, mulScalar } from './vec3';

export class Ray {
  constructor(private orig: Point3, private dir: Vec3) {}

  origin(): Point3 { return this.orig; }
  direction(): Vec3 { return this.dir; }
  at(t: number): Point3 { return add(this.orig, mulScalar(t, this.dir)); }
}


