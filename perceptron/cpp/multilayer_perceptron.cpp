#include "multilayer_perceptron.h"

#include <algorithm>
#include <cassert>
#include <functional>
#include <numeric>

MultilayerPerceptron::MultilayerPerceptron(std::vector<size_t> const & layer_sizes,
                                           std::vector<std::string> const & activation_functions)
  : layer_sizes(layer_sizes), num_layers(layer_sizes.size() - 1) {
  // Default activation functions if not provided
  if (activation_functions.empty()) {
    this->activation_functions.resize(num_layers);
    for (size_t i = 0; i < num_layers - 1; ++i) { this->activation_functions[i] = "relu"; }
    this->activation_functions[num_layers - 1] = "sigmoid";
  } else {
    this->activation_functions = activation_functions;
  }

  // Initialize random number generator
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_real_distribution<> dis(-0.01, 0.01);

  // Initialize parameters (weights and biases)
  for (size_t l = 1; l <= num_layers; ++l) {
    // Initialize weights with small random values
    Matrix W(layer_sizes[l - 1], Vector(layer_sizes[l]));
    for (size_t i = 0; i < layer_sizes[l - 1]; ++i) {
      for (size_t j = 0; j < layer_sizes[l]; ++j) { W[i][j] = dis(gen); }
    }
    parameters_w["W" + std::to_string(l)] = W;

    // Initialize biases with zeros
    Vector b(layer_sizes[l], 0.0);
    parameters_b["b" + std::to_string(l)] = b;
  }
}

MultilayerPerceptron::Matrix MultilayerPerceptron::forward(Matrix const & x) {
  // Input layer
  cache["A0"] = x;

  // Hidden and output layers
  for (size_t l = 1; l <= num_layers; ++l) {
    Matrix const & W      = parameters_w["W" + std::to_string(l)];
    Vector const & b      = parameters_b["b" + std::to_string(l)];
    Matrix const & A_prev = cache["A" + std::to_string(l - 1)];

    // Z = A_prev * W + b
    Matrix Z = matrix_dot(A_prev, W);
    for (size_t i = 0; i < Z.size(); ++i) {
      for (size_t j = 0; j < Z[i].size(); ++j) { Z[i][j] += b[j]; }
    }
    cache["Z" + std::to_string(l)] = Z;

    // Apply activation function
    Matrix A(Z.size(), Vector(Z[0].size()));
    for (size_t i = 0; i < Z.size(); ++i) {
      for (size_t j = 0; j < Z[i].size(); ++j) {
        A[i][j] = apply_activation(Z[i][j], activation_functions[l - 1]);
      }
    }
    cache["A" + std::to_string(l)] = A;
  }

  return cache["A" + std::to_string(num_layers)];
}

void MultilayerPerceptron::backward(Matrix const & x, Matrix const & y, double learning_rate) {
  size_t m = x.size();
  std::unordered_map<std::string, Matrix> gradients_w;
  std::unordered_map<std::string, Vector> gradients_b;

  // Output layer gradients
  Matrix const & AL = cache["A" + std::to_string(num_layers)];
  Matrix dA(AL.size(), Vector(AL[0].size()));
  for (size_t i = 0; i < AL.size(); ++i) {
    for (size_t j = 0; j < AL[i].size(); ++j) { dA[i][j] = AL[i][j] - y[i][j]; }
  }

  // Backpropagate through all layers
  for (int l = num_layers; l >= 1; --l) {
    Matrix const & A_prev = cache["A" + std::to_string(l - 1)];
    Matrix const & Z      = cache["Z" + std::to_string(l)];

    // Calculate dZ
    Matrix dZ;
    if (l == static_cast<int>(num_layers)) {
      dZ = dA;  // For sigmoid output and binary cross-entropy
    } else {
      dZ.resize(dA.size(), Vector(dA[0].size()));
      for (size_t i = 0; i < dA.size(); ++i) {
        for (size_t j = 0; j < dA[i].size(); ++j) {
          dZ[i][j] = dA[i][j] * apply_activation_derivative(Z[i][j], activation_functions[l - 1]);
        }
      }
    }

    // Calculate gradients for weights
    Matrix A_prev_T = matrix_transpose(A_prev);
    Matrix dW       = matrix_dot(A_prev_T, dZ);
    for (auto & row : dW) {
      for (auto & val : row) { val /= m; }
    }
    gradients_w["dW" + std::to_string(l)] = dW;

    // Calculate gradients for biases
    Vector db(dZ[0].size(), 0.0);
    for (size_t i = 0; i < dZ.size(); ++i) {
      for (size_t j = 0; j < dZ[i].size(); ++j) { db[j] += dZ[i][j]; }
    }
    for (auto & val : db) { val /= m; }
    gradients_b["db" + std::to_string(l)] = db;

    // Calculate dA for next layer (except for input layer)
    if (l > 1) {
      Matrix const & W = parameters_w["W" + std::to_string(l)];
      Matrix W_T       = matrix_transpose(W);
      dA               = matrix_dot(dZ, W_T);
    }
  }

  // Update parameters
  for (size_t l = 1; l <= num_layers; ++l) {
    Matrix & W        = parameters_w["W" + std::to_string(l)];
    Vector & b        = parameters_b["b" + std::to_string(l)];
    Matrix const & dW = gradients_w["dW" + std::to_string(l)];
    Vector const & db = gradients_b["db" + std::to_string(l)];

    for (size_t i = 0; i < W.size(); ++i) {
      for (size_t j = 0; j < W[i].size(); ++j) { W[i][j] -= learning_rate * dW[i][j]; }
    }

    for (size_t i = 0; i < b.size(); ++i) { b[i] -= learning_rate * db[i]; }
  }
}

double MultilayerPerceptron::relu(double x) const {
  return std::max(0.0, x);
}

double MultilayerPerceptron::sigmoid(double x) const {
  return 1.0 / (1.0 + std::exp(-x));
}

double MultilayerPerceptron::tanh(double x) const {
  return std::tanh(x);
}

double MultilayerPerceptron::relu_derivative(double x) const {
  return x > 0 ? 1.0 : 0.0;
}

double MultilayerPerceptron::sigmoid_derivative(double x) const {
  double s = sigmoid(x);
  return s * (1.0 - s);
}

double MultilayerPerceptron::tanh_derivative(double x) const {
  double t = tanh(x);
  return 1.0 - t * t;
}

double MultilayerPerceptron::apply_activation(double x, std::string const & activation) const {
  if (activation == "relu") {
    return relu(x);
  } else if (activation == "sigmoid") {
    return sigmoid(x);
  } else if (activation == "tanh") {
    return tanh(x);
  } else {
    throw std::invalid_argument("Unsupported activation function: " + activation);
  }
}

double MultilayerPerceptron::apply_activation_derivative(double x,
                                                         std::string const & activation) const {
  if (activation == "relu") {
    return relu_derivative(x);
  } else if (activation == "sigmoid") {
    return sigmoid_derivative(x);
  } else if (activation == "tanh") {
    return tanh_derivative(x);
  } else {
    throw std::invalid_argument("Unsupported activation function: " + activation);
  }
}

MultilayerPerceptron::Matrix MultilayerPerceptron::matrix_dot(Matrix const & a,
                                                              Matrix const & b) const {
  assert(!a.empty() && !b.empty() && a[0].size() == b.size());

  Matrix result(a.size(), Vector(b[0].size(), 0.0));
  for (size_t i = 0; i < a.size(); ++i) {
    for (size_t j = 0; j < b[0].size(); ++j) {
      for (size_t k = 0; k < b.size(); ++k) { result[i][j] += a[i][k] * b[k][j]; }
    }
  }
  return result;
}

MultilayerPerceptron::Matrix MultilayerPerceptron::matrix_transpose(Matrix const & m) const {
  if (m.empty()) { return Matrix(); }

  Matrix result(m[0].size(), Vector(m.size()));
  for (size_t i = 0; i < m.size(); ++i) {
    for (size_t j = 0; j < m[i].size(); ++j) { result[j][i] = m[i][j]; }
  }
  return result;
}
