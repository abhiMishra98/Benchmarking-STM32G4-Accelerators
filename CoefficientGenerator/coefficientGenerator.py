import numpy as np
from scipy import signal

# Design FIR low-pass filter
num_taps = 21
cutoff = 0.2  # normalized frequency (0–0.5 if fs is specified)
b = signal.firwin(num_taps, cutoff)

# Convert to Q15 fixed-point format
b_q15 = np.round(b * (2**15)).astype(int)

# Output file paths
header_path = "D:\\STM32G4\\Benchmarking-STM32G4-Accelerators\\BenchmarkingAccelerators\\Core\\Inc\\fir_coeffs.h"
source_path = "D:\\STM32G4\\Benchmarking-STM32G4-Accelerators\\BenchmarkingAccelerators\\Core\\Src\\fir_coeffs.c"

# Write header file
with open(header_path, "w") as hfile:
    hfile.write("#ifndef FIR_COEFFS_H\n#define FIR_COEFFS_H\n\n")
    hfile.write("#include <stdint.h>\n\n")
    hfile.write(f"#define NUM_TAPS {len(b_q15)}\n")
    hfile.write("extern const int16_t fir_coeffs[NUM_TAPS];\n\n")
    hfile.write("#endif // FIR_COEFFS_H\n")

# Write source file
with open(source_path, "w") as cfile:
    cfile.write('#include "fir_coeffs.h"\n\n')
    cfile.write("const int16_t fir_coeffs[NUM_TAPS] = {\n    ")
    cfile.write(", ".join(f"{coeff}" for coeff in b_q15))
    cfile.write("\n};\n")
