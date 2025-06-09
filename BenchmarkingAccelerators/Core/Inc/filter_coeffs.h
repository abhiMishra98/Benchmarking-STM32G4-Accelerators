#ifndef FILTER_COEFFS_H
#define FILTER_COEFFS_H

#include <stdint.h>

#define EMA_NUM_A_COEFFS 2
#define EMA_NUM_B_COEFFS 1
extern int16_t ema_a_coeffs[EMA_NUM_A_COEFFS];
extern int16_t ema_b_coeffs[EMA_NUM_B_COEFFS];

#endif // FILTER_COEFFS_H
