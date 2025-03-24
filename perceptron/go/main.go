package main

import (
	"fmt"
	"math"
	"math/rand"
	"time"
)

func main() {
	// Set random seed
	rand.Seed(time.Now().UnixNano())

	// Number of training epochs
	epochs := 10000

	// Generate training data for a 4-input logic operation
	trainingData := [][]float64{
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
		{1, 1, 1, 1},
	}

	// Labels (alternating 0,1 pattern as in the Python example)
	labels := [][]float64{
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
		{1},
	}

	// Initialize a multilayer perceptron with [4, 4, 1] architecture
	// input size 4, one hidden layer of size 4, output size 1
	net := NewMultilayerPerceptron(
		[]int{4, 4, 1},
		[]string{"relu", "sigmoid"},
	)

	learningRate := 0.1

	// Training loop
	for epoch := 0; epoch <= epochs; epoch++ {
		// Forward pass
		outputs := net.Forward(trainingData)

		// Compute loss (binary cross-entropy) every 1000 epochs
		if epoch%1000 == 0 {
			loss := 0.0
			for i := 0; i < len(labels); i++ {
				for j := 0; j < len(labels[i]); j++ {
					loss -= labels[i][j]*math.Log(outputs[i][j]) +
						(1-labels[i][j])*math.Log(1-outputs[i][j])
				}
			}
			loss /= float64(len(labels))
			fmt.Printf("Epoch %d, Loss: %.6f\n", epoch, loss)
		}

		// Backward pass (update weights)
		net.Backward(trainingData, labels, learningRate)
	}

	// Test the trained network
	finalOutputs := net.Forward(trainingData)
	fmt.Println("\nPredictions after training:")
	for i, input := range trainingData {
		fmt.Printf("Input: %v, Target: %.0f, Prediction: %.6f\n",
			input, labels[i][0], finalOutputs[i][0])
	}
}
