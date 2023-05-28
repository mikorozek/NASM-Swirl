#define _USE_MATH_DEFINES
#include <math.h>
#include <stdio.h>
#include <stdint.h>
#include "swirl.h"
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
    // Create a buffer for flipped rows
    RGBTRIPLE* flippedBuffer = (RGBTRIPLE*)calloc(height * width, sizeof(RGBTRIPLE));
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            flippedBuffer[i * width + j] = pixelArray[(height - i - 1) * width + j];
    }
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


void initDefaultSwirlFactor(double* swirlFactor)
{
    *swirlFactor = 0.005;
}


int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        printf("Usage: %s <imagePath>\n", argv[0]);
        return 1;
    }

    char* inputFile = argv[1];

    // Open input file
    FILE *inptr = fopen(inputFile, "r");
    if (inptr == NULL)
    {
        printf("Could not open %s.\n", inputFile);
        return 4;
    }

    // Read infile's BITMAPFILEHEADER
    BITMAPFILEHEADER bitmapFileheader;
    fread(&bitmapFileheader, sizeof(BITMAPFILEHEADER), 1, inptr);

    // Read infile's BITMAPINFOHEADER
    BITMAPINFOHEADER bitmapInfoheader;
    fread(&bitmapInfoheader, sizeof(BITMAPINFOHEADER), 1, inptr);

    fseek(inptr, 0, SEEK_SET);

    fseek(inptr, bitmapFileheader.bfOffBits, SEEK_SET);

    // Get image's dimensions
    int height = abs(bitmapInfoheader.biHeight);
    int width = bitmapInfoheader.biWidth;

    RGBTRIPLE* pixelArray = (RGBTRIPLE*)calloc(height * width, sizeof(RGBTRIPLE));

    // Determine padding for scanlines
    int padding = (4 - (width * sizeof(RGBTRIPLE)) % 4) % 4;

    // Iterate over infile's scanlines in reverse order
    for (int i = 0; i < height; i++)
    {
        // Calculate the offset in the pixel array for the current row
        RGBTRIPLE* row = pixelArray + i * width;

        // Read row into pixel array
        fread(row, sizeof(RGBTRIPLE), width, inptr);

        // Skip over padding
        fseek(inptr, padding, SEEK_CUR);
    }

    RGBTRIPLE* pixelArrayCopy = (RGBTRIPLE*)calloc(height * width, sizeof(RGBTRIPLE));

    if(pixelArrayCopy == NULL) {
        // Handle the error.
        fprintf(stderr, "Memory allocation for pixelArrayCopy failed\n");
        exit(1);
    }

    double swirlFactor;
    initDefaultSwirlFactor(&swirlFactor);

    swirl(pixelArray, pixelArrayCopy, width, height, swirlFactor);

    displayResult(pixelArrayCopy, width, height);

    return 0;
}
