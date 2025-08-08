import { Point3, Vec3 } from './vec3';
import { Ray } from './ray';
import { Interval } from './interval';

export interface Material {
  scatter(rIn: Ray, rec: HitRecord): { attenuation: Vec3; scattered: Ray } | null;
}

export class HitRecord {
  p!: Point3;
  normal!: Vec3;
  mat!: Material;
  t!: number;
  frontFace!: boolean;

  setFaceNormal(r: Ray, outwardNormal: Vec3): void {
    this.frontFace = dotLessThanZero(r, outwardNormal);
    this.normal = this.frontFace ? outwardNormal : outwardNormal.neg();
  }
}

function dotLessThanZero(r: Ray, outwardNormal: Vec3): boolean {
  const d = r.direction();
  return d.x() * outwardNormal.x() + d.y() * outwardNormal.y() + d.z() * outwardNormal.z() < 0;
}

export interface Hittable {
  hit(r: Ray, rayT: Interval, rec: HitRecord): boolean;
}


