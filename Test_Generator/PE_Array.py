import numpy as np
import os

def generate_test_data(num_rows=32, num_cols=16, data_width=8):
    # Generate random inputs
    # IFM: Vector of size NUM_ROWS
    # Values between -128 and 127 (signed 8-bit)
    ifm = np.random.randint(-128, 127, size=num_rows)
    
    # Weights: Matrix of size NUM_ROWS x NUM_COLS
    weights = np.random.randint(-128, 127, size=(num_rows, num_cols))
    
    # Calculate expected output
    # Result = IFM * Weights
    # IFM (1xR) * W (RxC) = (1xC)
    # Note: np.dot(1D, 2D) treats 1D as row vector
    psum = np.dot(ifm, weights)
    
    # Save to files
    # Use absolute path or relative to script location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.join(script_dir, "data")
    os.makedirs(data_dir, exist_ok=True)
    
    print(f"Generating data in {data_dir}")
    
    with open(os.path.join(data_dir, "ifm.txt"), "w") as f:
        for val in ifm:
            # Handle negative numbers for hex representation (8-bit)
            f.write(f"{val & 0xFF:02x}\n")
            
    with open(os.path.join(data_dir, "weights.txt"), "w") as f:
        for r in range(num_rows):
            for c in range(num_cols):
                val = weights[r, c]
                f.write(f"{val & 0xFF:02x}\n")
                
    with open(os.path.join(data_dir, "golden.txt"), "w") as f:
        for val in psum:
            # Output is 21 bits. Handle negative numbers.
            f.write(f"{val & 0x1FFFFF:06x}\n")

    print("Data generation complete.")

if __name__ == "__main__":
    generate_test_data()
