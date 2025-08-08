import { Color } from "./vec3";
import { writeColor } from "./color";

export class Image {
  private pixels: Color[];
  constructor(public readonly width: number, public readonly height: number) {
    this.pixels = new Array(width * height);
  }

  setPixel(x: number, y: number, color: Color) {
    this.pixels[y * this.width + x] = color;
  }

  toPPM(): string {
    let out = `P3\n${this.width} ${this.height}\n255\n`;
    for (let j = 0; j < this.height; j++) {
      for (let i = 0; i < this.width; i++) {
        out += writeColor(this.pixels[j * this.width + i]!);
      }
    }
    return out;
  }
}


