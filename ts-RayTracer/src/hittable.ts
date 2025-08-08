import { Interval } from "./interval";
import { Ray } from "./ray";
import { Point3, Vec3 } from "./vec3";

export interface Material {
  scatter(rIn: Ray, rec: HitRecord): { didScatter: boolean; attenuation: Vec3; scattered: Ray };
}

export class HitRecord {
  p!: Point3;
  normal!: Vec3;
  mat!: Material;
  t!: number;
  frontFace!: boolean;

  setFaceNormal(r: Ray, outwardNormal: Vec3) {
    this.frontFace = dot(r.direction(), outwardNormal) < 0;
    this.normal = this.frontFace ? outwardNormal : outwardNormal.neg();
  }
}

// local util to avoid import cycle
function dot(u: Vec3, v: Vec3): number {
  return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
}

export interface Hittable {
  hit(r: Ray, rayT: Interval, rec: HitRecord): boolean;
}


