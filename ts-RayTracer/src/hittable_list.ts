import { Hittable, HitRecord } from './hittable';
import { Interval } from './interval';
import { Ray } from './ray';

export class HittableList implements Hittable {
  public objects: Hittable[] = [];

  add(object: Hittable): void { this.objects.push(object); }
  clear(): void { this.objects = []; }

  hit(r: Ray, rayT: Interval, rec: HitRecord): boolean {
    const tempRec = new HitRecord();
    let hitAnything = false;
    let closestSoFar = rayT.max;

    for (const object of this.objects) {
      if (object.hit(r, new Interval(rayT.min, closestSoFar), tempRec)) {
        hitAnything = true;
        closestSoFar = tempRec.t;
        Object.assign(rec, tempRec);
      }
    }

    return hitAnything;
  }
}


