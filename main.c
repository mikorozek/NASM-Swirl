#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include "swirl.h"
#include "bmp.h"

int main(int argc, char *argv[]) {
  if (argc != 3) {
    printf("Usage: %s <image_path> <swirl_factor>\n", argv[0]);
    return 1;
  }

  char *input_file = argv[1];
  double swirl_factor = atof(argv[2]);

  // Open input file
  FILE *inptr = fopen(input_file, "r");
  if (inptr == NULL)
  {
      printf("Error! Cannot open %s.\n", input_file);
      return 4;
  }

  // Read infile's BITMAPFILEHEADER
  BITMAPFILEHEADER bitmap_file_header;
  fread(&bitmap_file_header, sizeof(BITMAPFILEHEADER), 1, inptr);

  // Read infile's BITMAPINFOHEADER
  BITMAPINFOHEADER bitmap_info_header;
  fread(&bitmap_info_header, sizeof(BITMAPINFOHEADER), 1, inptr);

  // Get image's dimensions
  int height = abs(bitmap_info_header.biHeight);
  int width = bitmap_info_header.biWidth;
  RGBTRIPLE(*pixel_array)[width] = calloc(height, width * sizeof(RGBTRIPLE));

  // Iterate over infile's scanlines
  for (int i = 0; i < height; i++)
  {
      // Read row into pixel array
      fread(pixel_array[i], sizeof(RGBTRIPLE), width, inptr);

      // Skip over padding
      fseek(inptr, padding, SEEK_CUR);
  }
  return 0;
}