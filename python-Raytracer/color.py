import math


def linear_to_gamma(linear_component):
    """Convert linear to gamma (gamma 2)"""
    return math.sqrt(linear_component) if linear_component > 0.0 else 0.0


def clamp(x, min_val, max_val):
    """Clamp x to the range [min_val, max_val]"""
    if x < min_val:
        return min_val
    elif x > max_val:
        return max_val
    else:
        return x


def write_color(file, pixel_color):
    """Write the color to the given file stream"""
    # Get components
    r = pixel_color.x()
    g = pixel_color.y()
    b = pixel_color.z()

    # Apply gamma correction
    r = linear_to_gamma(r)
    g = linear_to_gamma(g)
    b = linear_to_gamma(b)

    # Translate to [0,255] range
    intensity_min = 0.000
    intensity_max = 0.999
    r_byte = int(256 * clamp(r, intensity_min, intensity_max))
    g_byte = int(256 * clamp(g, intensity_min, intensity_max))
    b_byte = int(256 * clamp(b, intensity_min, intensity_max))

    # Write the bytes
    file.write(f"{r_byte} {g_byte} {b_byte}\n")
