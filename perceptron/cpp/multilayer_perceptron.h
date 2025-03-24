#ifndef MULTILAYER_PERCEPTRON_H
#define MULTILAYER_PERCEPTRON_H

#include <cmath>
#include <random>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

class MultilayerPerceptron {
  public:
    using Matrix = std::vector<std::vector<double>>;
    using Vector = std::vector<double>;

    // Constructor
    MultilayerPerceptron(std::vector<size_t> const & layer_sizes,
                         std::vector<std::string> const & activation_functions = {});

    // Forward pass
    Matrix forward(Matrix const & x);

    // Backward pass (training)
    void backward(Matrix const & x, Matrix const & y, double learning_rate);

  private:
    // Network architecture
    size_t num_layers;
    std::vector<size_t> layer_sizes;
    std::vector<std::string> activation_functions;

    // Parameters (weights and biases) and cache for forward/backward passes
    std::unordered_map<std::string, Matrix> parameters_w;
    std::unordered_map<std::string, Vector> parameters_b;
    std::unordered_map<std::string, Matrix> cache;

    // Activation functions
    double relu(double x) const;
    double sigmoid(double x) const;
    double relu_derivative(double x) const;
    double sigmoid_derivative(double x) const;
    double tanh(double x) const;
    double tanh_derivative(double x) const;
    double apply_activation(double x, std::string const & activation) const;
    double apply_activation_derivative(double x, std::string const & activation) const;

    // Helper functions
    Matrix matrix_dot(Matrix const & a, Matrix const & b) const;
    Matrix matrix_transpose(Matrix const & m) const;
};

#endif  // MULTILAYER_PERCEPTRON_H
