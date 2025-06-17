import math
import random

INFINITY = float("inf")
PI = math.pi


def degrees_to_radians(degrees: float) -> float:
    return degrees * PI / 180.0


def random_double() -> float:
    return random.random()


class Interval:
    def __init__(self, min_val: int | float, max_val: int | float):
        self.min = min_val
        self.max = max_val

    def contains(self, x: int | float):
        return self.min <= x <= self.max
