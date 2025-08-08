export class Interval {
  constructor(public min: number, public max: number) {}

  static empty = new Interval(Number.POSITIVE_INFINITY, Number.NEGATIVE_INFINITY);
  static universe = new Interval(Number.NEGATIVE_INFINITY, Number.POSITIVE_INFINITY);

  size(): number { return this.max - this.min; }
  contains(x: number): boolean { return this.min <= x && x <= this.max; }
  surrounds(x: number): boolean { return this.min < x && x < this.max; }
  clamp(x: number): number { return x < this.min ? this.min : x > this.max ? this.max : x; }
}


