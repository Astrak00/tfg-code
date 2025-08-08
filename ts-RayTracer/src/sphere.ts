import { Hittable, HitRecord } from './hittable';
import { Interval } from './interval';
import { Ray } from './ray';
import { Point3, Vec3, sub, dot, mulVecScalar } from './vec3';

export class Sphere implements Hittable {
  constructor(private center: Point3, private radius: number, private mat: any) {
    this.radius = Math.max(0, radius);
  }

  hit(r: Ray, rayT: Interval, rec: HitRecord): boolean {
    const oc = sub(this.center, r.origin());
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
    const outwardNormal = divByScalar(sub(rec.p, this.center), this.radius);
    rec.setFaceNormal(r, outwardNormal);
    rec.mat = this.mat;
    return true;
  }
}

function divByScalar(v: Vec3, t: number): Vec3 {
  return mulVecScalar(v, 1 / t);
}


