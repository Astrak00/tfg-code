use rand::Rng;
use std::collections::HashMap;

pub struct MultilayerPerceptron {
    num_layers: usize,
    layer_sizes: Vec<usize>,
    activation_functions: Vec<String>,
    parameters_w: HashMap<String, Vec<Vec<f64>>>,
    parameters_b: HashMap<String, Vec<f64>>,
    cache: HashMap<String, Vec<Vec<f64>>>,
}

impl MultilayerPerceptron {
    pub fn new(layer_sizes: Vec<usize>, activation_functions: Option<Vec<String>>) -> Self {
        let num_layers = layer_sizes.len() - 1;

        // Default activation functions if not provided
        let activation_functions = match activation_functions {
            Some(funcs) => funcs,
            None => {
                let mut funcs = vec!["relu".to_string(); num_layers];
                if !funcs.is_empty() {
                    funcs[num_layers - 1] = "sigmoid".to_string();
                }
                funcs
            }
        };

        let mut parameters_w = HashMap::new();
        let mut parameters_b = HashMap::new();
        let mut rng = rand::thread_rng();

        // Initialize parameters
        for l in 1..=num_layers {
            // Initialize weights with small random values
            let mut w = vec![vec![0.0; layer_sizes[l]]; layer_sizes[l - 1]];
            for row in &mut w {
                for val in row {
                    *val = rng.gen::<f64>() * 0.01;
                }
            }
            parameters_w.insert(format!("W{}", l), w);

            // Initialize biases with zeros
            parameters_b.insert(format!("b{}", l), vec![0.0; layer_sizes[l]]);
        }

        MultilayerPerceptron {
            num_layers,
            layer_sizes,
            activation_functions,
            parameters_w,
            parameters_b,
            cache: HashMap::new(),
        }
    }

    fn relu(&self, x: f64) -> f64 {
        x.max(0.0)
    }

    fn sigmoid(&self, x: f64) -> f64 {
        1.0 / (1.0 + (-x).exp())
    }

    fn tanh(&self, x: f64) -> f64 {
        x.tanh()
    }

    fn relu_derivative(&self, x: f64) -> f64 {
        if x > 0.0 {
            1.0
        } else {
            0.0
        }
    }

    fn sigmoid_derivative(&self, x: f64) -> f64 {
        let s = self.sigmoid(x);
        s * (1.0 - s)
    }

    fn tanh_derivative(&self, x: f64) -> f64 {
        let t = self.tanh(x);
        1.0 - t * t
    }

    fn apply_activation(&self, x: f64, activation: &str) -> f64 {
        match activation {
            "relu" => self.relu(x),
            "sigmoid" => self.sigmoid(x),
            "tanh" => self.tanh(x),
            _ => panic!("Unsupported activation function: {}", activation),
        }
    }

    fn apply_activation_derivative(&self, x: f64, activation: &str) -> f64 {
        match activation {
            "relu" => self.relu_derivative(x),
            "sigmoid" => self.sigmoid_derivative(x),
            "tanh" => self.tanh_derivative(x),
            _ => panic!("Unsupported activation function: {}", activation),
        }
    }

    pub fn forward(&mut self, x: Vec<Vec<f64>>) -> Vec<Vec<f64>> {
        // Input layer
        self.cache.insert("A0".to_string(), x);

        // Hidden and output layers
        for l in 1..=self.num_layers {
            let w = self.parameters_w.get(&format!("W{}", l)).unwrap().clone();
            let b = self.parameters_b.get(&format!("b{}", l)).unwrap().clone();
            let a_prev = self.cache.get(&format!("A{}", l - 1)).unwrap().clone();

            // Z = A_prev * W + b
            let mut z = vec![vec![0.0; b.len()]; a_prev.len()];
            for i in 0..a_prev.len() {
                for j in 0..b.len() {
                    z[i][j] = b[j]; // Add bias
                    for k in 0..a_prev[i].len() {
                        z[i][j] += a_prev[i][k] * w[k][j];
                    }
                }
            }
            self.cache.insert(format!("Z{}", l), z.clone());

            // Apply activation function
            let activation = &self.activation_functions[l - 1];
            let mut a = vec![vec![0.0; z[0].len()]; z.len()];
            for (i, row) in z.iter().enumerate() {
                for (j, &val) in row.iter().enumerate() {
                    a[i][j] = self.apply_activation(val, activation);
                }
            }
            self.cache.insert(format!("A{}", l), a.clone());
        }

        self.cache
            .get(&format!("A{}", self.num_layers))
            .unwrap()
            .clone()
    }

    pub fn backward(&mut self, x: Vec<Vec<f64>>, y: Vec<Vec<f64>>, learning_rate: f64) {
        let m = x.len() as f64;
        let mut gradients_w = HashMap::new();
        let mut gradients_b = HashMap::new();

        // Output layer gradients
        let output_layer = self.cache.get(&format!("A{}", self.num_layers)).unwrap();
        let mut da = vec![vec![0.0; output_layer[0].len()]; output_layer.len()];
        for i in 0..output_layer.len() {
            for j in 0..output_layer[i].len() {
                da[i][j] = output_layer[i][j] - y[i][j];
            }
        }

        // Backpropagate through all layers
        for l in (1..=self.num_layers).rev() {
            let a_prev = self.cache.get(&format!("A{}", l - 1)).unwrap();
            let z = self.cache.get(&format!("Z{}", l)).unwrap();

            // Calculate dZ
            let dz = if l == self.num_layers {
                // For sigmoid output and binary cross-entropy
                da.clone()
            } else {
                let mut dz = vec![vec![0.0; da[0].len()]; da.len()];
                let activation = &self.activation_functions[l - 1];
                for i in 0..da.len() {
                    for j in 0..da[i].len() {
                        dz[i][j] = da[i][j] * self.apply_activation_derivative(z[i][j], activation);
                    }
                }
                dz
            };

            // Calculate dW - transpose A_prev, then multiply by dZ and divide by m
            let mut dw = vec![vec![0.0; dz[0].len()]; a_prev[0].len()];
            for i in 0..a_prev[0].len() {
                for j in 0..dz[0].len() {
                    for k in 0..a_prev.len() {
                        dw[i][j] += a_prev[k][i] * dz[k][j];
                    }
                    dw[i][j] /= m;
                }
            }
            gradients_w.insert(format!("dW{}", l), dw);

            // Calculate db - sum dZ along axis 0 and divide by m
            let mut db = vec![0.0; dz[0].len()];
            for i in 0..dz.len() {
                for j in 0..dz[i].len() {
                    db[j] += dz[i][j];
                }
            }
            for val in &mut db {
                *val /= m;
            }
            gradients_b.insert(format!("db{}", l), db);

            // Calculate dA for next layer (except for input layer)
            if l > 1 {
                let w = self.parameters_w.get(&format!("W{}", l)).unwrap();
                let mut next_da = vec![vec![0.0; a_prev[0].len()]; dz.len()];
                for i in 0..dz.len() {
                    for j in 0..a_prev[0].len() {
                        for k in 0..dz[i].len() {
                            next_da[i][j] += dz[i][k] * w[j][k];
                        }
                    }
                }
                da = next_da;
            }
        }

        // Update parameters
        for l in 1..=self.num_layers {
            let w = self.parameters_w.get_mut(&format!("W{}", l)).unwrap();
            let dw = gradients_w.get(&format!("dW{}", l)).unwrap();
            for i in 0..w.len() {
                for j in 0..w[i].len() {
                    w[i][j] -= learning_rate * dw[i][j];
                }
            }

            let b = self.parameters_b.get_mut(&format!("b{}", l)).unwrap();
            let db = gradients_b.get(&format!("db{}", l)).unwrap();
            for i in 0..b.len() {
                b[i] -= learning_rate * db[i];
            }
        }
    }
}
