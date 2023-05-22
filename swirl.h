#ifndef _SWIRL_H
#define _SWIRL_H
#include "bmp.h"

void swirl(RGBTRIPLE* origin_pixel_array, RGBTRIPLE* copy_pixel_array, int width, int height, double swirl_factor);

#endif
