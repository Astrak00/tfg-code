"""
This module contains a 3D vector class made of floats.
"""
from typing import Tuple
import math
import random


class Vec3():
    """A 3D vector class made of floats."""
    def __init__(self, e1: float, e2: float, e3: float):
        self.e: Tuple[float, float, float] = (e1, e2, e3)

    def x(self) -> float:
        """Return the x component of the vector."""
        return self.e[0]

    def y(self) -> float:
        """Return the y component of the vector."""
        return self.e[1]

    def z(self) -> float:
        """Return the z component of the vector."""
        return self.e[2]

    def __add__(self, other: 'Vec3') -> 'Vec3':
        return Vec3(self.e[0] + other.e[0], self.e[1] + other.e[1], self.e[2] + other.e[2])

    def __iadd__(self, other: 'Vec3') -> 'Vec3':
        return Vec3(self.e[0] + other.e[0], self.e[1] + other.e[1], self.e[2] + other.e[2])

    def __mul__(self, other: 'Vec3') -> 'Vec3':
        if isinstance(other, Vec3):
            return Vec3(self.e[0] * other.e[0], self.e[1] * other.e[1], self.e[2] * other.e[2])
        if isinstance(other, float):
            return Vec3(self.e[0] * other, self.e[1] * other, self.e[2] * other)
        raise NotImplementedError(f"Multiplication not implemented for type {type(other)}")

    def __imul__(self, other: 'Vec3') -> 'Vec3':
        return Vec3(self.e[0] * other.e[0], self.e[1] * other.e[1], self.e[2] * other.e[2])

    def __sub__(self, other: 'Vec3') -> 'Vec3':
        if isinstance(other, tuple) and len(other) == 3:
            return Vec3(self.e[0] - other[0], self.e[1] - other[1], self.e[2] - other[2])
        return Vec3(self.e[0] - other.e[0], self.e[1] - other.e[1], self.e[2] - other.e[2])

    def __rmul__(self, val: float) -> 'Vec3':
        return Vec3(self.e[0] * val, self.e[1] * val, self.e[2] * val)

    def __truediv__(self, t: float) -> 'Vec3':
        return self * (1 / t)

    def __rdiv__(self, t: float) -> 'Vec3':
        return self * (1 / t)

    def __neg__(self) -> 'Vec3':
        return Vec3(-self.e[0], -self.e[1], -self.e[2])

    def __str__(self):
        return f"({self.e[0]}, {self.e[1]}, {self.e[2]})"

    def __repr__(self):
        return f"Vec3({self.e[0]}, {self.e[1]}, {self.e[2]})"

    def dot(self, other: 'Vec3') -> float:
        """Return the dot product of two vectors."""
        return self.e[0] * other.e[0] + self.e[1] * other.e[1] + self.e[2] * other.e[2]

    def cross(self, other: 'Vec3') -> 'Vec3':
        """Return the cross product of two vectors."""
        return Vec3(self.e[1] * other.e[2] - self.e[2] * other.e[1],
                    self.e[2] * other.e[0] - self.e[0] * other.e[2],
                    self.e[0] * other.e[1] - self.e[1] * other.e[0])

    def length_squared(self) -> float:
        """Return the squared length of the vector."""
        return self.e[0] ** 2 + self.e[1] ** 2 + self.e[2] ** 2

    def length(self) -> float:
        """Return the length of the vector."""
        return math.sqrt(self.length_squared())

    def near_zero(self) -> bool:
        """Return True if the vector is close to zero in all dimensions."""
        s: float = 1e-8
        return (abs(self.e[0]) < s) and (abs(self.e[1]) < s) and (abs(self.e[2]) < s)

    def random(self) -> 'Vec3':
        """Return a random vector."""
        return Vec3(random.random(), random.random(), random.random())


    def unit_vector(self) -> 'Vec3':
        """Return the unit vector of the vector."""
        return self / self.length()

    def random_on_hemisphere(self, normal: 'Vec3') -> 'Vec3':
        """Return a random vector on a hemisphere."""
        on_unit_sphere = random_unit_vector()
        if on_unit_sphere.dot(normal) > 0:  # In the same hemisphere as the normal
            return on_unit_sphere
        return -on_unit_sphere

    def reflect(self, n: 'Vec3') -> 'Vec3':
        """Return the reflection of the vector."""
        return self - 2 * self.dot(n) * n

    def refract(self, n: 'Vec3', etai_over_etat: float) -> 'Vec3':
        """Return the refraction of the vector."""
        cos_theta = min(-self.dot(n), 1.0)
        r_out_perp = etai_over_etat * (self + cos_theta * n)
        r_out_parallel = -math.sqrt(abs(1.0 - r_out_perp.length_squared())) * n
        return r_out_perp + r_out_parallel


def random_range(min_val: float, max_val: float) -> Vec3:
    """Return a random vector within a range."""
    return Vec3(random.uniform(min_val, max_val),
                random.uniform(min_val, max_val),
                random.uniform(min_val, max_val))

def random_unit_vector() -> Vec3:
    """Return a random unit vector."""
    while True:
        p = random_range(-1, 1)
        lensq = p.length_squared()
        if 1e-160 < lensq <= 1.0:
            return p.unit_vector()

def random_in_unit_disk() -> Vec3:
    """Return a random vector in a unit disk."""
    while True:
        p: Vec3 = Vec3(random.uniform(-1, 1), random.uniform(-1, 1), 0)
        if p.length_squared() >= 1:
            continue
        return p


class Point3(Vec3):
    """
    Alias for Vec3.
    """
