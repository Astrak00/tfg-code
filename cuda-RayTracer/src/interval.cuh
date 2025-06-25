#ifndef INTERVAL_CUH
#define INTERVAL_CUH

#ifdef __CUDACC__
#define CUDA_CALLABLE_MEMBER __host__ __device__
#else
#define CUDA_CALLABLE_MEMBER
#endif

class interval {
  public:
    double min, max;

    CUDA_CALLABLE_MEMBER constexpr interval() : min(+1e30), max(-1e30) { }  // Default interval is empty

    CUDA_CALLABLE_MEMBER constexpr interval(double min, double max) : min(min), max(max) { }

    CUDA_CALLABLE_MEMBER constexpr double size() const { return max - min; }

    CUDA_CALLABLE_MEMBER constexpr bool contains(double x) const { return min <= x && x <= max; }

    CUDA_CALLABLE_MEMBER constexpr bool surrounds(double x) const { return min < x && x < max; }

    CUDA_CALLABLE_MEMBER constexpr double clamp(double x) const {
      if (x < min) { return min; }
      if (x > max) { return max; }
      return x;
    }
};

#endif
