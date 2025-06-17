#ifndef INTERVAL_HPP
#define INTERVAL_HPP

class interval {
  public:
    double min, max;

    constexpr interval() : min(+infinity), max(-infinity) { }  // Default interval is empty

    constexpr interval(double min, double max) : min(min), max(max) { }

    constexpr double size() const { return max - min; }

    constexpr bool contains(double x) const { return min <= x && x <= max; }

    constexpr bool surrounds(double x) const { return min < x && x < max; }

    constexpr double clamp(double x) const {
      if (x < min) { return min; }
      if (x > max) { return max; }
      return x;
    }

    static interval const empty, universe;
};

interval const interval::empty    = interval(+infinity, -infinity);
interval const interval::universe = interval(-infinity, +infinity);

#endif
