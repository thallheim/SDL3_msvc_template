#include <SDL3/SDL.h>

const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;

int main(int argc, char *argv[]) {
  (void)argc;
  (void)argv;

  if (!SDL_Init(SDL_INIT_VIDEO)) {
    
    SDL_Log("SDL_Init failed (%s)", SDL_GetError());
    return 1;
  }
  SDL_Log("Wooo");
  SDL_Window *window = NULL;
  SDL_Renderer *renderer = NULL;

  if (!SDL_CreateWindowAndRenderer("I AM GAME", SCREEN_WIDTH, SCREEN_HEIGHT,
                                   0, &window, &renderer))
    {
      SDL_Log("SDL_CreateWindowAndRenderer failed (%s)", SDL_GetError());
      SDL_Quit();
      return 1;
    }

  while (1) {
    int finished = 0;
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
      if (event.type == SDL_EVENT_QUIT) {
        finished = 1;
        break;
      }
    }
    if (finished) {
      SDL_Log("Baiii");
      break;
    }

    SDL_SetRenderDrawColor(renderer, 80, 80, 80, SDL_ALPHA_OPAQUE);
    SDL_RenderClear(renderer);
    SDL_RenderPresent(renderer);
  }

  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);

  SDL_Quit();
  return 0;
}
