import numpy as np

class MultilayerPerceptron:
    def __init__(self, layer_sizes, activation_functions=None):
        """
        Initialize a multilayer perceptron
        
        Parameters:
        layer_sizes -- list of integers, the size of each layer including input layer
        activation_functions -- list of strings, activation function for each layer (except input)
        """
        self.num_layers = len(layer_sizes) - 1  # Number of layers (excluding input layer)
        self.layer_sizes = layer_sizes

        # Default activation functions if not provided
        if activation_functions is None:
            # Use ReLU for all hidden layers and sigmoid for output
            activation_functions = ['relu'] * (self.num_layers - 1) + ['sigmoid']

        self.activation_functions = activation_functions

        # Initialize parameters
        self.parameters = {}
        for l in range(1, self.num_layers + 1):
            self.parameters[f'W{l}'] = np.random.randn(layer_sizes[l-1], layer_sizes[l]) * 0.01
            self.parameters[f'b{l}'] = np.zeros((1, layer_sizes[l]))

        # Storage for forward pass
        self.cache = {}

    def relu(self, x):
        return np.maximum(0, x)

    def sigmoid(self, x):
        return 1 / (1 + np.exp(-x))

    def tanh(self, x):
        return np.tanh(x)

    def relu_derivative(self, x):
        return x > 0

    def sigmoid_derivative(self, x):
        s = self.sigmoid(x)
        return s * (1 - s)

    def tanh_derivative(self, x):
        t = self.tanh(x)
        return 1 - t**2

    def apply_activation(self, x, activation):
        if activation == 'relu':
            return self.relu(x)
        elif activation == 'sigmoid':
            return self.sigmoid(x)
        elif activation == 'tanh':
            return self.tanh(x)
        else:
            raise ValueError(f"Unsupported activation function: {activation}")

    def apply_activation_derivative(self, x, activation):
        if activation == 'relu':
            return self.relu_derivative(x)
        elif activation == 'sigmoid':
            return self.sigmoid_derivative(x)
        elif activation == 'tanh':
            return self.tanh_derivative(x)
        else:
            raise ValueError(f"Unsupported activation function: {activation}")

    def forward(self, x):
        # Ensure x is a 2D array
        if x.ndim == 1:
            x = x.reshape(1, -1)

        # Input layer
        self.cache['A0'] = x

        # Hidden and output layers
        for l in range(1, self.num_layers + 1):
            W = self.parameters[f'W{l}']
            b = self.parameters[f'b{l}']
            A_prev = self.cache[f'A{l-1}']

            Z = np.dot(A_prev, W) + b
            A = self.apply_activation(Z, self.activation_functions[l-1])

            self.cache[f'Z{l}'] = Z
            self.cache[f'A{l}'] = A

        # Return output of last layer
        return self.cache[f'A{self.num_layers}']

    def backward(self, x:np.ndarray, y:np.ndarray, l_rate:float):
        m = x.shape[0]

        # Gradients storage
        gradients = {}

        # Output layer gradients
        dA = self.cache[f'A{self.num_layers}'] - y

        # Backpropagate through all layers
        for l in reversed(range(1, self.num_layers + 1)):
            A_prev = self.cache[f'A{l-1}']
            Z = self.cache[f'Z{l}']

            if l == self.num_layers:
                dZ = dA  # For sigmoid output and binary cross-entropy
            else:
                dZ = dA * self.apply_activation_derivative(Z, self.activation_functions[l-1])

            gradients[f'dW{l}'] = np.dot(A_prev.T, dZ) / m
            gradients[f'db{l}'] = np.sum(dZ, axis=0, keepdims=True) / m
            
            if l > 1:  # No need to calculate dA for input layer
                dA = np.dot(dZ, self.parameters[f'W{l}'].T)

        # Update parameters
        for l in range(1, self.num_layers + 1):
            self.parameters[f'W{l}'] -= l_rate * gradients[f'dW{l}']
            self.parameters[f'b{l}'] -= l_rate * gradients[f'db{l}']

if __name__ == "__main__":
    EPOCHS = 10_000

    # Generate training data for a 3-input AND + OR logic gate
    training_data_3 = np.array([
		[0, 0, 0, 0],
		[0, 0, 0, 1],
		[0, 0, 1, 0],
		[0, 0, 1, 1],
		[0, 1, 0, 0],
		[0, 1, 0, 1],
		[0, 1, 1, 0],
		[0, 1, 1, 1],
		[1, 0, 0, 0],
		[1, 0, 0, 1],
		[1, 0, 1, 0],
		[1, 0, 1, 1],
		[1, 1, 0, 0],
		[1, 1, 0, 1],
		[1, 1, 1, 0],
		[1, 1, 1, 1],
    ], dtype=np.float32)

    labels_3 = np.array([[0], [1], [0], [1], [0], [1], [0], [1], [0],
                         [1], [0], [1], [0], [1], [0], [1]], dtype=np.float32)

    # Initialize a multilayer perceptron with [3, 4, 1] architecture
    # input size 3, one hidden layer of size 4, output size 1
    net = MultilayerPerceptron(layer_sizes=[4, 4, 1],
                               activation_functions=['tanh', 'sigmoid'])

    learning_rate = 0.1

    # Training loop
    for epoch in range(EPOCHS+1):
        # Forward pass
        outputs = net.forward(training_data_3)

        # Compute loss (binary cross-entropy)
        loss = -np.mean(labels_3 * np.log(outputs + 1e-10) + (1 - labels_3) * np.log(1 - outputs + 1e-10))

        # Backward pass
        net.backward(training_data_3, labels_3, learning_rate)

        if epoch % 10_000 == 0:
            # Print loss every 10000 epochs
            print(f"Epoch {epoch}/{EPOCHS}, Loss: {loss}")

    # Test the network
    for input_data in training_data_3:
        prediction = net.forward(input_data).item()
        print(f"Input: {input_data}, Prediction: {round(prediction)}")
