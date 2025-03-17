from vector import Vector

class Ray:
    def __init__(self, origin=Vector(), direction=Vector()):
        self.origin = origin
        self.direction = direction.normalize()
    
    def point_at(self, t):
        return self.origin + self.direction * t
