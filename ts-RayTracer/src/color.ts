import { Color } from './vec3';
import { Interval } from './interval';

export function linearToGamma(linearComponent: number): number {
  if (linearComponent > 0) return Math.sqrt(linearComponent);
  return 0;
}

export function writeColor(pixelColor: Color): string {
  const r = pixelColor.x();
  const g = pixelColor.y();
  const b = pixelColor.z();

  const rGamma = linearToGamma(r);
  const gGamma = linearToGamma(g);
  const bGamma = linearToGamma(b);

  const intensity = new Interval(0.0, 0.999);
  const rbyte = Math.floor(256 * intensity.clamp(rGamma));
  const gbyte = Math.floor(256 * intensity.clamp(gGamma));
  const bbyte = Math.floor(256 * intensity.clamp(bGamma));

  return `${rbyte} ${gbyte} ${bbyte}`;
}


