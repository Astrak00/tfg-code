package main

import (
	"fmt"
	"math"
	"math/rand"
)

// MultilayerPerceptron represents a multilayer perceptron neural network
type MultilayerPerceptron struct {
	numLayers           int
	layerSizes          []int
	activationFunctions []string
	parameters          map[string]interface{}
	cache               map[string]interface{}
}

// NewMultilayerPerceptron creates a new multilayer perceptron
func NewMultilayerPerceptron(layerSizes []int, activationFunctions []string) *MultilayerPerceptron {
	mlp := &MultilayerPerceptron{
		numLayers:  len(layerSizes) - 1,
		layerSizes: layerSizes,
		parameters: make(map[string]interface{}),
		cache:      make(map[string]interface{}),
	}

	// Default activation functions if not provided
	if activationFunctions == nil {
		activationFunctions = make([]string, mlp.numLayers)
		for i := 0; i < mlp.numLayers-1; i++ {
			activationFunctions[i] = "relu"
		}
		activationFunctions[mlp.numLayers-1] = "sigmoid"
	}
	mlp.activationFunctions = activationFunctions

	// Initialize parameters
	for l := 1; l <= mlp.numLayers; l++ {
		// Initialize weights with small random values
		W := make([][]float64, layerSizes[l-1])
		for i := range W {
			W[i] = make([]float64, layerSizes[l])
			for j := range W[i] {
				W[i][j] = rand.Float64() * 0.01
			}
		}
		mlp.parameters[fmt.Sprintf("W%d", l)] = W

		// Initialize biases with zeros
		b := make([]float64, layerSizes[l])
		mlp.parameters[fmt.Sprintf("b%d", l)] = b
	}

	return mlp
}

// Relu activation function
func (mlp *MultilayerPerceptron) relu(x float64) float64 {
	if x > 0 {
		return x
	}
	return 0
}

// Sigmoid activation function
func (mlp *MultilayerPerceptron) sigmoid(x float64) float64 {
	return 1.0 / (1.0 + math.Exp(-x))
}

// Tanh activation function
func (mlp *MultilayerPerceptron) tanh(x float64) float64 {
	return math.Tanh(x)
}

// ReluDerivative computes derivative of relu function
func (mlp *MultilayerPerceptron) reluDerivative(x float64) float64 {
	if x > 0 {
		return 1.0
	}
	return 0.0
}

// SigmoidDerivative computes derivative of sigmoid function
func (mlp *MultilayerPerceptron) sigmoidDerivative(x float64) float64 {
	s := mlp.sigmoid(x)
	return s * (1.0 - s)
}

// TanhDerivative computes derivative of tanh function
func (mlp *MultilayerPerceptron) tanhDerivative(x float64) float64 {
	t := mlp.tanh(x)
	return 1.0 - t*t
}

// ApplyActivation applies the specified activation function to a value
func (mlp *MultilayerPerceptron) applyActivation(x float64, activation string) float64 {
	switch activation {
	case "relu":
		return mlp.relu(x)
	case "sigmoid":
		return mlp.sigmoid(x)
	case "tanh":
		return mlp.tanh(x)
	default:
		panic(fmt.Sprintf("Unsupported activation function: %s", activation))
	}
}

// ApplyActivationDerivative applies the derivative of the specified activation function
func (mlp *MultilayerPerceptron) applyActivationDerivative(x float64, activation string) float64 {
	switch activation {
	case "relu":
		return mlp.reluDerivative(x)
	case "sigmoid":
		return mlp.sigmoidDerivative(x)
	case "tanh":
		return mlp.tanhDerivative(x)
	default:
		panic(fmt.Sprintf("Unsupported activation function: %s", activation))
	}
}

// Forward performs a forward pass through the network
func (mlp *MultilayerPerceptron) Forward(x [][]float64) [][]float64 {
	// Input layer
	mlp.cache["A0"] = x

	// Hidden and output layers
	for l := 1; l <= mlp.numLayers; l++ {
		W := mlp.parameters[fmt.Sprintf("W%d", l)].([][]float64)
		b := mlp.parameters[fmt.Sprintf("b%d", l)].([]float64)
		APrev := mlp.cache[fmt.Sprintf("A%d", l-1)].([][]float64)

		// Z = np.dot(A_prev, W) + b
		Z := make([][]float64, len(APrev))
		for i := range Z {
			Z[i] = make([]float64, len(b))
			for j := range Z[i] {
				Z[i][j] = b[j] // Add bias
				for k := 0; k < len(APrev[i]); k++ {
					Z[i][j] += APrev[i][k] * W[k][j]
				}
			}
		}
		mlp.cache[fmt.Sprintf("Z%d", l)] = Z

		// Apply activation function
		activation := mlp.activationFunctions[l-1]
		A := make([][]float64, len(Z))
		for i := range A {
			A[i] = make([]float64, len(Z[i]))
			for j := range A[i] {
				A[i][j] = mlp.applyActivation(Z[i][j], activation)
			}
		}
		mlp.cache[fmt.Sprintf("A%d", l)] = A
	}

	return mlp.cache[fmt.Sprintf("A%d", mlp.numLayers)].([][]float64)
}

// Backward performs backpropagation to update weights and biases
func (mlp *MultilayerPerceptron) Backward(x [][]float64, y [][]float64, learningRate float64) {
	m := len(x)
	gradients := make(map[string]interface{})

	// Output layer gradients (A - y)
	outputLayer := mlp.cache[fmt.Sprintf("A%d", mlp.numLayers)].([][]float64)
	dA := make([][]float64, len(outputLayer))
	for i := range dA {
		dA[i] = make([]float64, len(outputLayer[i]))
		for j := range dA[i] {
			dA[i][j] = outputLayer[i][j] - y[i][j]
		}
	}

	// Backpropagate through all layers
	for l := mlp.numLayers; l >= 1; l-- {
		APrev := mlp.cache[fmt.Sprintf("A%d", l-1)].([][]float64)
		Z := mlp.cache[fmt.Sprintf("Z%d", l)].([][]float64)

		// Calculate dZ based on whether it's the output layer or not
		var dZ [][]float64
		if l == mlp.numLayers {
			dZ = dA // For sigmoid output and binary cross-entropy
		} else {
			dZ = make([][]float64, len(dA))
			for i := range dZ {
				dZ[i] = make([]float64, len(dA[i]))
				for j := range dZ[i] {
					dZ[i][j] = dA[i][j] * mlp.applyActivationDerivative(Z[i][j], mlp.activationFunctions[l-1])
				}
			}
		}

		// Calculate gradients for weights and biases
		W := mlp.parameters[fmt.Sprintf("W%d", l)].([][]float64)

		// dW = APrev.T * dZ / m
		dW := make([][]float64, len(W))
		for i := range dW {
			dW[i] = make([]float64, len(W[i]))
		}

		for i := 0; i < len(APrev[0]); i++ {
			for j := 0; j < len(dZ[0]); j++ {
				for k := 0; k < len(APrev); k++ {
					dW[i][j] += APrev[k][i] * dZ[k][j]
				}
				dW[i][j] /= float64(m)
			}
		}
		gradients[fmt.Sprintf("dW%d", l)] = dW

		// db = sum(dZ, axis=0) / m
		db := make([]float64, len(dZ[0]))
		for i := 0; i < len(dZ); i++ {
			for j := 0; j < len(dZ[0]); j++ {
				db[j] += dZ[i][j]
			}
		}
		for j := range db {
			db[j] /= float64(m)
		}
		gradients[fmt.Sprintf("db%d", l)] = db

		// Calculate dA for next layer (except for input layer)
		if l > 1 {
			nextDA := make([][]float64, len(dZ))
			for i := range nextDA {
				nextDA[i] = make([]float64, len(APrev[i]))
				for j := range nextDA[i] {
					for k := 0; k < len(dZ[i]); k++ {
						nextDA[i][j] += dZ[i][k] * W[j][k]
					}
				}
			}
			dA = nextDA
		}
	}

	// Update parameters
	for l := 1; l <= mlp.numLayers; l++ {
		W := mlp.parameters[fmt.Sprintf("W%d", l)].([][]float64)
		dW := gradients[fmt.Sprintf("dW%d", l)].([][]float64)
		for i := range W {
			for j := range W[i] {
				W[i][j] -= learningRate * dW[i][j]
			}
		}

		b := mlp.parameters[fmt.Sprintf("b%d", l)].([]float64)
		db := gradients[fmt.Sprintf("db%d", l)].([]float64)
		for i := range b {
			b[i] -= learningRate * db[i]
		}
	}
}
