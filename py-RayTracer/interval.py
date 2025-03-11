"""
This module contains a class representing a closed interval on the real number line.
"""
from math import inf

class Interval():
    """A class representing a closed interval on the real number line."""
    def __init__(self, min_val: float= inf, max_val: float = -inf):
        self.min_val = min_val
        self.max_val = max_val

    def size(self) -> float:
        """Return the size of the interval."""
        return self.max_val - self.min_val

    def contains(self, t: float) -> bool:
        """Return True if the interval contains t."""
        return self.min_val <= t <= self.max_val

    def surrounds(self, t: float) -> bool:
        """Return True if the interval surrounds t."""
        return self.min_val < t < self.max_val

    def clamp(self, x: float) -> float:
        """Return t clamped to the interval."""
        if x < self.min_val:
            return self.min_val
        if x > self.max_val:
            return self.max_val
        return x
