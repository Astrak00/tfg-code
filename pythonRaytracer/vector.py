import math

class Vector:
    def __init__(self, x=0, y=0, z=0):
        self.x = x
        self.y = y
        self.z = z

    def __add__(self, other):
        if isinstance(other, Vector):
            return Vector(self.x + other.x, self.y + other.y, self.z + other.z)
        elif isinstance(other, (int, float)):
            return Vector(self.x + other, self.y + other, self.z + other)
        else:
            raise TypeError(f"unsupported operand type(s) for +: 'Vector' and '{type(other).__name__}'")
    
    def __radd__(self, other):
        return self.__add__(other)
    
    def __sub__(self, other):
        return Vector(self.x - other.x, self.y - other.y, self.z - other.z)
    
    def __mul__(self, scalar):
        if isinstance(scalar, (int, float)):
            return Vector(self.x * scalar, self.y * scalar, self.z * scalar)
        elif isinstance(scalar, Vector):
            # Element-wise multiplication
            return Vector(self.x * scalar.x, self.y * scalar.y, self.z * scalar.z)
        else:
            raise TypeError(f"unsupported operand type(s) for *: 'Vector' and '{type(scalar).__name__}'")
    
    def __rmul__(self, scalar):
        return self.__mul__(scalar)
    
    def __neg__(self):
        return Vector(-self.x, -self.y, -self.z)
    
    def __truediv__(self, scalar):
        return Vector(self.x / scalar, self.y / scalar, self.z / scalar)
    
    def length(self):
        return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
    
    def normalize(self):
        length = self.length()
        if length > 0:
            return self / length
        return Vector()
    
    def dot(self, other):
        return self.x * other.x + self.y * other.y + self.z * other.z
    
    def cross(self, other):
        return Vector(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x
        )
    
    def reflect(self, normal):
        return self - 2 * self.dot(normal) * normal
