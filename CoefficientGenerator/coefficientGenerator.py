import numpy as np
from scipy import signal

# # Design FIR low-pass filter
# num_taps = 21
# cutoff = 0.2  #normalized frequency. 1 being the Nyquist frequency, so cutoff shud be 0<cutoff<1
# b = signal.firwin(num_taps, cutoff)


#  # Design FIR high-pass filter
# # num_taps = 21
# # cutoff = 0.2  #normalized frequency. 1 being the Nyquist frequency, so cutoff shud be 0<cutoff<1
# # b = signal.firwin(num_taps,cutoff,pass_zero=False) #for high pass filter

# # Convert to Q15 fixed-point format with clipping to int16_t range. Use for FIR filter
# q15_scale = 2**15
# b_q15 = np.round(b * q15_scale).astype(np.int32)  # temporarily promote to int32 to handle overflows
# b_q15 = np.clip(b_q15, -32768, 32767).astype(np.int16)  # clip to int16_t range



# Output file paths
header_path = "D:\\STM32G4\\Benchmarking-STM32G4-Accelerators\\BenchmarkingAccelerators\\Core\\Inc\\filter_coeffs.h"
source_path = "D:\\STM32G4\\Benchmarking-STM32G4-Accelerators\\BenchmarkingAccelerators\\Core\\Src\\filter_coeffs.c"

# # Write header file
# with open(header_path, "w") as hfile:
#     hfile.write("#ifndef FILTER_COEFFS_H\n#define FILTER_COEFFS_H\n\n")
#     hfile.write("#include <stdint.h>\n\n")
#     hfile.write(f"#define NUM_TAPS {len(b_q15)}\n")
#     hfile.write("extern int16_t fir_coeffs[NUM_TAPS];\n\n")
#     hfile.write("#endif // FILTER_COEFFS_H\n")

# # Write source file
# with open(source_path, "w") as cfile:
#     cfile.write('#include "filter_coeffs.h"\n\n')
#     cfile.write("int16_t fir_coeffs[NUM_TAPS] = {\n    ")
#     cfile.write(", ".join(f"{coeff}" for coeff in b_q15))
#     cfile.write("\n};\n")


# Design IIR Low-Pass filter
# --- Parameters ---
alpha = 0.9  # smoothing factor (smaller = more smoothing)

# --- IIR EMA Coefficients ---
b_coeffs = [alpha]                   # b0
a_coeffs = [1.0, -(1.0 - alpha)]     # a0 = 1, a1 = -(1 - alpha)

# --- Convert to Q15 ---
def to_q15(vals):
    q15 = np.round(np.array(vals) * 32768).astype(np.int32)
    return np.clip(q15, -32768, 32767).astype(np.int16)

b_q15 = to_q15(b_coeffs)
a_q15 = to_q15(a_coeffs)

    # --- Write header ---
with open(header_path, "w") as hfile:
    hfile.write("#ifndef FILTER_COEFFS_H\n#define FILTER_COEFFS_H\n\n")
    hfile.write("#include <stdint.h>\n\n")
    hfile.write("#define EMA_NUM_A_COEFFS 2\n")
    hfile.write("#define EMA_NUM_B_COEFFS 1\n")
    hfile.write("extern int16_t ema_a_coeffs[EMA_NUM_A_COEFFS];\n")
    hfile.write("extern int16_t ema_b_coeffs[EMA_NUM_B_COEFFS];\n\n")
    hfile.write("#endif // FILTER_COEFFS_H\n")

# --- Write source ---
with open(source_path, "w") as cfile:
    cfile.write('#include "filter_coeffs.h"\n\n')
    cfile.write("int16_t ema_a_coeffs[EMA_NUM_A_COEFFS] = {\n    ")
    cfile.write(", ".join(f"{val}" for val in a_q15))
    cfile.write("\n};\n\n")
    cfile.write("int16_t ema_b_coeffs[EMA_NUM_B_COEFFS] = {\n    ")
    cfile.write(", ".join(f"{val}" for val in b_q15))
    cfile.write("\n};\n")
