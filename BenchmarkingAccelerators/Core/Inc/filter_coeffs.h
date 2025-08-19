#ifndef FILTER_COEFFS_H
#define FILTER_COEFFS_H

#include <stdint.h>

#define EMA_NUM_B_COEFFS 1
#define EMA_NUM_A_COEFFS 1
extern int16_t ema_b_coeffs[EMA_NUM_B_COEFFS];
extern int16_t ema_a_coeffs[EMA_NUM_A_COEFFS];

#endif // IIR_COEFFS_H
