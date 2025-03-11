"""
A module to represent the color of a pixel.
"""
from math import sqrt
from interval import Interval
from vec3 import Vec3


class Color(Vec3):
    """A class to represent the color of a pixel."""


def linear_to_gamma(linear_component: float) -> float:
    """Convert a linear color component to gamma."""
    if linear_component > 0:
        return sqrt(linear_component)
    return 0

def write_color(color: Color) -> str:
    """Write the color to the standard output."""
    r = linear_to_gamma(color.x())
    g = linear_to_gamma(color.y())
    b = linear_to_gamma(color.z())

    interval = Interval(0.000, 0.999)

    rbyte = int(256 * interval.clamp(r))
    gbyte = int(256 * interval.clamp(g))
    bbyte = int(256 * interval.clamp(b))

    return f"{rbyte} {gbyte} {bbyte} \n"
