#include "multilayer_perceptron.h"
#include "multilayer_perceptron.cpp"
#include <iostream>
#include <iomanip>
#include <cmath>

int main()
{
  // Number of training epochs
  const int EPOCHS = 10000;

  // Generate training data for a 4-input logic operation
  std::vector<std::vector<double>> training_data = {
      {0, 0, 0, 0},
      {0, 0, 0, 1},
      {0, 0, 1, 0},
      {0, 0, 1, 1},
      {0, 1, 0, 0},
      {0, 1, 0, 1},
      {0, 1, 1, 0},
      {0, 1, 1, 1},
      {1, 0, 0, 0},
      {1, 0, 0, 1},
      {1, 0, 1, 0},
      {1, 0, 1, 1},
      {1, 1, 0, 0},
      {1, 1, 0, 1},
      {1, 1, 1, 0},
      {1, 1, 1, 1}};

  // Labels (alternating 0,1 pattern as in the Python example)
  std::vector<std::vector<double>> labels = {
      {0},
      {1},
      {0},
      {1},
      {0},
      {1},
      {0},
      {1},
      {0},
      {1},
      {0},
      {1},
      {0},
      {1},
      {0},
      {1}};

  // Initialize a multilayer perceptron with [4, 4, 1] architecture
  // input size 4, one hidden layer of size 4, output size 1
  MultilayerPerceptron net({4, 4, 1}, {"relu", "sigmoid"});

  double learning_rate = 0.1;

  // Training loop
  for (int epoch = 0; epoch <= EPOCHS; ++epoch)
  {
    // Forward pass
    auto outputs = net.forward(training_data);

    // Compute loss (binary cross-entropy) every 1000 epochs
    if (epoch % 1000 == 0)
    {
      double loss = 0.0;
      for (size_t i = 0; i < labels.size(); ++i)
      {
        for (size_t j = 0; j < labels[i].size(); ++j)
        {
          loss -= labels[i][j] * std::log(outputs[i][j]) +
                  (1 - labels[i][j]) * std::log(1 - outputs[i][j]);
        }
      }
      loss /= labels.size();
      std::cout << "Epoch " << epoch << ", Loss: " << std::fixed << std::setprecision(6) << loss << std::endl;
    }

    // Backward pass (update weights)
    net.backward(training_data, labels, learning_rate);
  }

  // Test the trained network
  auto final_outputs = net.forward(training_data);
  std::cout << "\nPredictions after training:" << std::endl;
  for (size_t i = 0; i < training_data.size(); ++i)
  {
    std::cout << "Input: [";
    for (size_t j = 0; j < training_data[i].size(); ++j)
    {
      std::cout << training_data[i][j];
      if (j < training_data[i].size() - 1)
        std::cout << ", ";
    }
    std::cout << "], Target: " << labels[i][0]
              << ", Prediction: " << std::fixed << std::setprecision(6) << final_outputs[i][0] << std::endl;
  }

  return 0;
}
