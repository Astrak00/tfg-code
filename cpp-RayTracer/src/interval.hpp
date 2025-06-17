#ifndef INTERVAL_HPP
#define INTERVAL_HPP

class interval {
  public:
    double min, max;

    /**
 * @brief Constructs an empty interval with no valid range.
 *
 * Initializes the interval so that `min` is positive infinity and `max` is negative infinity, representing an empty interval.
 */
constexpr interval() : min(+infinity), max(-infinity) { }  /**
 * @brief Constructs an interval with specified lower and upper bounds.
 *
 * @param min The lower bound of the interval.
 * @param max The upper bound of the interval.
 */

    constexpr interval(double min, double max) : min(min), max(max) { }

    /**
 * @brief Returns the length of the interval.
 *
 * @return The difference between max and min bounds.
 */
constexpr double size() const { return max - min; }

    /**
 * @brief Checks if a value lies within or on the boundaries of the interval.
 *
 * @param x The value to test.
 * @return true if x is greater than or equal to min and less than or equal to max; false otherwise.
 */
constexpr bool contains(double x) const { return min <= x && x <= max; }

    /**
 * @brief Checks if a value lies strictly within the interval.
 *
 * @param x The value to test.
 * @return true if x is greater than min and less than max; false otherwise.
 */
constexpr bool surrounds(double x) const { return min < x && x < max; }

    /**
     * @brief Clamps a value to the interval bounds.
     *
     * Returns the value itself if it lies within the interval; otherwise, returns the nearest bound (`min` or `max`).
     *
     * @param x The value to clamp.
     * @return double The clamped value.
     */
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
