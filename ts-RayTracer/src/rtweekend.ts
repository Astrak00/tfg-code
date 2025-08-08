// Constants
export const infinity = Number.POSITIVE_INFINITY;
export const pi = Math.PI;

// Utility Functions
export function degreesToRadians(degrees: number): number {
  return (degrees * pi) / 180.0;
}

// Thread-local randomness is unnecessary in Node; use a per-module RNG
export function randomDouble(): number {
  return Math.random();
}

export function randomDoubleRange(min: number, max: number): number {
  return min + (max - min) * randomDouble();
}


