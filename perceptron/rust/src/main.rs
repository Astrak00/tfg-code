mod multilayer_perceptron;

use multilayer_perceptron::MultilayerPerceptron;

fn main() {
    // Number of training epochs
    let epochs = 10000;

    // Generate training data for a 4-input logic operation
    let training_data = vec![
        vec![0.0, 0.0, 0.0, 0.0],
        vec![0.0, 0.0, 0.0, 1.0],
        vec![0.0, 0.0, 1.0, 0.0],
        vec![0.0, 0.0, 1.0, 1.0],
        vec![0.0, 1.0, 0.0, 0.0],
        vec![0.0, 1.0, 0.0, 1.0],
        vec![0.0, 1.0, 1.0, 0.0],
        vec![0.0, 1.0, 1.0, 1.0],
        vec![1.0, 0.0, 0.0, 0.0],
        vec![1.0, 0.0, 0.0, 1.0],
        vec![1.0, 0.0, 1.0, 0.0],
        vec![1.0, 0.0, 1.0, 1.0],
        vec![1.0, 1.0, 0.0, 0.0],
        vec![1.0, 1.0, 0.0, 1.0],
        vec![1.0, 1.0, 1.0, 0.0],
        vec![1.0, 1.0, 1.0, 1.0],
    ];

    // Labels (alternating 0,1 pattern as in the Python example)
    let labels = vec![
        vec![0.0],
        vec![1.0],
        vec![0.0],
        vec![1.0],
        vec![0.0],
        vec![1.0],
        vec![0.0],
        vec![1.0],
        vec![0.0],
        vec![1.0],
        vec![0.0],
        vec![1.0],
        vec![0.0],
        vec![1.0],
        vec![0.0],
        vec![1.0],
    ];

    // Initialize a multilayer perceptron with [4, 4, 1] architecture
    // input size 4, one hidden layer of size 4, output size 1
    let mut net = MultilayerPerceptron::new(
        vec![4, 4, 1],
        Some(vec!["relu".to_string(), "sigmoid".to_string()]),
    );

    let learning_rate = 0.1;

    // Training loop
    for epoch in 0..=epochs {
        // Forward pass
        let outputs = net.forward(training_data.clone());

        // Compute loss (binary cross-entropy) every 1000 epochs
        if epoch % 1000 == 0 {
            let mut loss = 0.0;
            for i in 0..labels.len() {
                for j in 0..labels[i].len() {
                    loss -= labels[i][j] * outputs[i][j].ln()
                        + (1.0 - labels[i][j]) * (1.0 - outputs[i][j]).ln();
                }
            }
            loss /= labels.len() as f64;
            println!("Epoch {}, Loss: {:.6}", epoch, loss);
        }

        // Backward pass (update weights)
        net.backward(training_data.clone(), labels.clone(), learning_rate);
    }

    // Test the trained network
    let final_outputs = net.forward(training_data.clone());
    println!("\nPredictions after training:");
    for i in 0..training_data.len() {
        print!("Input: [");
        for (j, &val) in training_data[i].iter().enumerate() {
            print!("{}", val);
            if j < training_data[i].len() - 1 {
                print!(", ");
            }
        }
        println!(
            "], Target: {}, Prediction: {:.6}",
            labels[i][0], final_outputs[i][0]
        );
    }
}
