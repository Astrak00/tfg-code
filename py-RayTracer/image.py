"""
A module containing a class that represent an image.
"""
import time
from color import Color, write_color

class Image():
    """
    A class to represent an image.
    """
    def __init__(self, width, height):
        self._width = width
        self._height = height
        self._pixels = [Color(0, 0, 0) for _ in range(width * height)]

    def set_pixel(self, x, y, color_local: Color):
        """
        Get the pixel at the given coordinates.
        """
        self._pixels[y * self._width + x] = color_local

    def write(self, filename, print_output: bool = False):
        """
        Write the image to a file.
        """
        if print_output:
            print(f"P3\n{self._width} {self._height}\n255")
            for c in self._pixels:
                print(write_color(c))
        else:
            with open(filename, "w", encoding="utf-8") as file:
                file.write(f"P3\n{self._width} {self._height}\n255\n")
                for c in self._pixels:
                    file.write(write_color(c))


if __name__ == "__main__":
    import gc
    gc.disable()
    SIZE = 3000
    image = Image(SIZE, SIZE)
    start = time.time()
    for i in range(SIZE):
        for j in range(SIZE):
            color = Color(j / SIZE, i / SIZE, 0)
            image.set_pixel(j, i, color)
    print("done generating:", time.time() - start)
    save = time.time()
    image.write("output_pypy.ppm")
    print("done saving:", time.time() - save)
