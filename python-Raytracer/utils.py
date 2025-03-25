import math
import random

INFINITY = float("inf")
PI = math.pi


def degrees_to_radians(degrees):
    return degrees * PI / 180.0


def random_double():
    return random.random()


class Interval:
    def __init__(self, min_val, max_val):
        self.min = min_val
        self.max = max_val

    def contains(self, x):
        return self.min <= x <= self.max
