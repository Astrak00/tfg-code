export const InfinityF = Number.POSITIVE_INFINITY;
export const Pi = Math.PI;

export function degreesToRadians(degrees: number): number {
  return (degrees * Pi) / 180.0;
}

export function randomDouble(): number {
  return Math.random();
}

export function randomDoubleRange(min: number, max: number): number {
  return min + (max - min) * randomDouble();
}


