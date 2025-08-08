import { Interval } from "./interval";
import { HitRecord, Hittable, Material } from "./hittable";
import { Ray } from "./ray";
import { Point3, Vec3 } from "./vec3";

function dot(u: Vec3, v: Vec3): number {
  return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
}

export class Sphere implements Hittable {
  constructor(public center: Point3, public radius: number, public mat: Material) {
    this.radius = Math.max(0, radius);
  }

  hit(r: Ray, rayT: Interval, rec: HitRecord): boolean {
    const oc = this.center.sub(r.origin());
    const a = r.direction().lengthSquared();
    const h = dot(r.direction(), oc);
    const c = oc.lengthSquared() - this.radius * this.radius;
    const discriminant = h * h - a * c;
    if (discriminant < 0) return false;
    const sqrtd = Math.sqrt(discriminant);
    let root = (h - sqrtd) / a;
    if (!rayT.surrounds(root)) {
      root = (h + sqrtd) / a;
      if (!rayT.surrounds(root)) return false;
    }
    rec.t = root;
    rec.p = r.at(rec.t);
    const outwardNormal = rec.p.sub(this.center).mulScalar(1 / this.radius);
    rec.setFaceNormal(r, outwardNormal);
    rec.mat = this.mat;
    return true;
  }
}


