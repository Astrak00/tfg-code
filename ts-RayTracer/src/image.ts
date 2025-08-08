import { Color } from './vec3';
import { writeColor } from './color';

export class Image {
  private pixels: Color[];

  constructor(private width: number, private height: number) {
    this.pixels = new Array(width * height);
  }

  pixel(x: number, y: number): Color | undefined {
    const idx = y * this.width + x;
    return this.pixels[idx];
  }

  setPixel(x: number, y: number, c: Color): void {
    this.pixels[y * this.width + x] = c;
  }

  toPPM(): string {
    let out = `P3\n${this.width} ${this.height}\n255\n`;
    for (let j = 0; j < this.height; j++) {
      for (let i = 0; i < this.width; i++) {
        out += writeColor(this.pixels[j * this.width + i]);
        out += '\n';
      }
    }
    return out;
  }
}


