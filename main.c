#define _USE_MATH_DEFINES
#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include "swirl.h"
#include "bmp.h"
#include <SDL2/SDL.h>
#include <stdbool.h>



void displayResult(RGBTRIPLE* pixelArray, int width, int height) {
    // Create a window
    SDL_Window* window = SDL_CreateWindow("Display Result", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, SDL_WINDOW_SHOWN);
    if (window == NULL) {
        printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_Quit();
        return;
    }

    // Create a renderer
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (renderer == NULL) {
        printf("Renderer could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return;
    }

    // Create a texture
    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_BGR24, SDL_TEXTUREACCESS_STATIC, width, height);
    if (texture == NULL) {
        printf("Texture could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return;
    }

    // Create a buffer for flipped rows
    RGBTRIPLE* flippedBuffer = (RGBTRIPLE*)calloc(height * width, sizeof(RGBTRIPLE));
    for (int i = 0; i < height; i++) {
        memcpy(&flippedBuffer[i * width], &pixelArray[(height - i - 1) * width], width * sizeof(RGBTRIPLE));
    }

    // Update the texture with pixel data
    SDL_UpdateTexture(texture, NULL, flippedBuffer, width * sizeof(RGBTRIPLE));

    // Clear the renderer
    SDL_RenderClear(renderer);

    // Copy the texture to the renderer
    SDL_RenderCopy(renderer, texture, NULL, NULL);

    // Display the contents of the renderer
    SDL_RenderPresent(renderer);

    // Wait for the window to be closed
    SDL_Event e;
    bool quit = false;
    while (!quit) {
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) {
                quit = true;
            }
        }
    }

    // Cleanup
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    free(flippedBuffer);
    SDL_Quit();
}

int main(int argc, char *argv[]) {
  if (argc != 3) {
    printf("Usage: %s <image_path> <swirl_factor>\n", argv[0]);
    return 1;
  }

  char *input_file = argv[1];

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
  RGBTRIPLE* origin_pixel_array = (RGBTRIPLE*)calloc(height * width, sizeof(RGBTRIPLE*));

  RGBTRIPLE* copy_pixel_array = (RGBTRIPLE*)calloc(height * width, sizeof(RGBTRIPLE*));

  // Determine padding for scanlines
  int padding = (4 - (width * sizeof(RGBTRIPLE)) % 4) % 4;

  // Iterate over infile's scanlines
  for (int i = 0; i < height; i++)
  {
      RGBTRIPLE* row = origin_pixel_array + i * width;
      // Read row into pixel array
      fread(row, sizeof(RGBTRIPLE), width, inptr);

      // Skip over padding
      fseek(inptr, padding, SEEK_CUR);
  }

  swirl(origin_pixel_array, copy_pixel_array, width, height, 0.05);

  displayResult(copy_pixel_array, width, height);

  return 0;
}