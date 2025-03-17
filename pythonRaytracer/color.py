import math
from vector import Vector

def write_color(pixel_color, samples_per_pixel):
    # Divide the color by the number of samples and gamma-correct for gamma=2.0
    r = pixel_color.x
    g = pixel_color.y
    b = pixel_color.z
    
    # Scale and gamma correction
    scale = 1.0 / samples_per_pixel
    r = math.sqrt(scale * r)
    g = math.sqrt(scale * g)
    b = math.sqrt(scale * b)
    
    # Translate to integer values between 0 and 255
    ir = int(256 * max(0, min(0.999, r)))
    ig = int(256 * max(0, min(0.999, g)))
    ib = int(256 * max(0, min(0.999, b)))
    
    return f"{ir} {ig} {ib}"
