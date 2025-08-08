import { Color } from "./vec3";

export function linearToGamma(linearComponent: number): number {
  return linearComponent > 0 ? Math.sqrt(linearComponent) : 0;
}

export function clamp(x: number, min: number, max: number): number {
  if (x < min) return min;
  if (x > max) return max;
  return x;
}

export function writeColor(pixelColor: Color): string {
  let r = pixelColor.x();
  let g = pixelColor.y();
  let b = pixelColor.z();

  r = linearToGamma(r);
  g = linearToGamma(g);
  b = linearToGamma(b);

  const intensity = { min: 0.0, max: 0.999 };
  const rByte = Math.floor(256 * clamp(r, intensity.min, intensity.max));
  const gByte = Math.floor(256 * clamp(g, intensity.min, intensity.max));
  const bByte = Math.floor(256 * clamp(b, intensity.min, intensity.max));
  return `${rByte} ${gByte} ${bByte}\n`;
}


