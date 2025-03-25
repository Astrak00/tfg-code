#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cmath>
#include <stdexcept>

struct Pixel
{
  int r, g, b;
};

struct PpmImage
{
  int width, height;
  int maxVal;
  std::vector<Pixel> pixels;
};

PpmImage readPpm(const std::string &filename)
{
  std::ifstream file(filename);
  if (!file)
  {
    throw std::runtime_error("Cannot open file: " + filename);
  }

  std::string magic;
  file >> magic;
  if (magic != "P3")
  {
    std::cerr << "Unsupported PPM format (only P3 supported): " << magic << "\n";
    throw std::runtime_error("Unsupported PPM format (only P3 supported): " + magic);
  }

  PpmImage image;
  file >> image.width >> image.height >> image.maxVal;

  image.pixels.resize(image.width * image.height);
  for (int i = 0; i < image.width * image.height; i++)
  {
    file >> image.pixels[i].r >> image.pixels[i].g >> image.pixels[i].b;
  }

  return image;
}

void writePpm(const std::string &filename, const PpmImage &image)
{
  std::ofstream file(filename);
  if (!file)
  {
    throw std::runtime_error("Cannot write to file: " + filename);
  }

  file << "P3\n";
  file << image.width << " " << image.height << "\n";
  file << image.maxVal << "\n";

  for (int i = 0; i < image.width * image.height; i++)
  {
    file << image.pixels[i].r << " "
         << image.pixels[i].g << " "
         << image.pixels[i].b << "\n";
  }
}

PpmImage calculateDifference(const PpmImage &img1, const PpmImage &img2)
{
  if (img1.width != img2.width || img1.height != img2.height)
  {
    throw std::runtime_error("Images have different dimensions");
  }

  PpmImage diff;
  diff.width = img1.width;
  diff.height = img1.height;
  diff.maxVal = 255;
  diff.pixels.resize(diff.width * diff.height);

  for (int i = 0; i < diff.width * diff.height; i++)
  {
    // Calculate absolute difference for each channel
    diff.pixels[i].r = std::abs(img1.pixels[i].r - img2.pixels[i].r);
    diff.pixels[i].g = std::abs(img1.pixels[i].g - img2.pixels[i].g);
    diff.pixels[i].b = std::abs(img1.pixels[i].b - img2.pixels[i].b);
  }

  return diff;
}

int main(int argc, char *argv[])
{
  if (argc != 3)
  {
    std::cerr << "Usage: " << argv[0] << " <ppm_file1> <ppm_file2>\n";
    return 1;
  }

  try
  {
    PpmImage img1 = readPpm(argv[1]);
    PpmImage img2 = readPpm(argv[2]);

    std::cout << "Reading PPM files:\n";
    std::cout << "Image 1: " << img1.width << "x" << img1.height << "\n";
    std::cout << "Image 2: " << img2.width << "x" << img2.height << "\n";

    if (img1.width != img2.width || img1.height != img2.height)
    {
      std::cerr << "Error: Images have different dimensions\n";
      return 1;
    }

    PpmImage diff = calculateDifference(img1, img2);

    // Generate output filename based on input files
    std::string outFilename = "diff_output.ppm";
    writePpm(outFilename, diff);

    std::cout << "Difference image saved to: " << outFilename << "\n";
  }
  catch (const std::exception &e)
  {
    std::cerr << "Error: " << e.what() << "\n";
    return 1;
  }

  return 0;
}
