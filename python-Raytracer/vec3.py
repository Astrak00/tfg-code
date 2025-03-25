import math
import random


class Vec3:
    def __init__(self, e0=0.0, e1=0.0, e2=0.0):
        self.e = [e0, e1, e2]

    def x(self):
        return self.e[0]

    def y(self):
        return self.e[1]

    def z(self):
        return self.e[2]

    def __getitem__(self, idx):
        return self.e[idx]

    def __neg__(self):
        return Vec3(-self.e[0], -self.e[1], -self.e[2])

    def __add__(self, other):
        return Vec3(
            self.e[0] + other.e[0], self.e[1] + other.e[1], self.e[2] + other.e[2]
        )

    def __sub__(self, other):
        return Vec3(
            self.e[0] - other.e[0], self.e[1] - other.e[1], self.e[2] - other.e[2]
        )

    def __mul__(self, other):
        if isinstance(other, (int, float)):
            return Vec3(self.e[0] * other, self.e[1] * other, self.e[2] * other)
        return Vec3(
            self.e[0] * other.e[0], self.e[1] * other.e[1], self.e[2] * other.e[2]
        )

    def __rmul__(self, other):
        return self * other

    def __truediv__(self, other):
        return Vec3(self.e[0] / other, self.e[1] / other, self.e[2] / other)

    def __str__(self):
        return f"{self.e[0]} {self.e[1]} {self.e[2]}"

    def length(self):
        return math.sqrt(self.length_squared())

    def length_squared(self):
        return self.e[0] * self.e[0] + self.e[1] * self.e[1] + self.e[2] * self.e[2]

    def near_zero(self):
        s = 1e-8
        return (abs(self.e[0]) < s) and (abs(self.e[1]) < s) and (abs(self.e[2]) < s)


# Type aliases
Point3 = Vec3
Color = Vec3


# Utility functions
def dot(u, v):
    return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2]


def cross(u, v):
    return Vec3(
        u.e[1] * v.e[2] - u.e[2] * v.e[1],
        u.e[2] * v.e[0] - u.e[0] * v.e[2],
        u.e[0] * v.e[1] - u.e[1] * v.e[0],
    )


def unit_vector(v):
    return v / v.length()


def random_vec3_range(min_val, max_val):
    return Vec3(
        min_val + random.random() * (max_val - min_val),
        min_val + random.random() * (max_val - min_val),
        min_val + random.random() * (max_val - min_val),
    )


def random_in_unit_disk():
    while True:
        p = Vec3(random.random() * 2.0 - 1.0, random.random() * 2.0 - 1.0, 0.0)
        if p.length_squared() < 1.0:
            return p


def random_unit_vector():
    while True:
        p = random_vec3_range(-1.0, 1.0)
        len_sq = p.length_squared()
        if 1e-160 < len_sq <= 1.0:
            return p / math.sqrt(len_sq)


def reflect(v, n):
    return v - n * (2.0 * dot(v, n))


def refract(uv, n, etai_over_etat):
    cos_theta = min(dot(-uv, n), 1.0)
    r_out_perp = (uv + n * cos_theta) * etai_over_etat
    r_out_parallel = n * (-math.sqrt(abs(1.0 - r_out_perp.length_squared())))
    return r_out_perp + r_out_parallel
