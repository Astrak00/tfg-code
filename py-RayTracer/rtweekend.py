"""Utility functions for the Ray Tracing in One Weekend series."""

from math import pi
import random

INFINITY = float('inf')
PI = pi

def degrees_to_radians(degrees):
    """Convert degrees to radians."""
    return degrees * PI / 180.0

def radians_to_degrees(radians):
    """Convert radians to degrees."""
    return radians * 180.0 / PI

def random_double():
    """Returns a random real in [0,1)."""
    return random.random()

def random_double_range(min_val, max_val):
    """Returns a random real in [min_val, max_val)."""
    return min_val + (max_val-min_val)*random_double()
