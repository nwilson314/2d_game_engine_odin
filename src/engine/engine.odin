package engine

import "core:log"
import glm "core:math/linalg/glsl"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import ecs "../ecs"
import asset_store "../asset_store"


game: Game

Game :: struct {
    window: ^sdl.Window,
    renderer: ^sdl.Renderer,
    running: bool,
    millisecs_previous_frame: u32,
    window_width: i32,
    window_height: i32,
    registry: ^ecs.Registry,
    asset_store: ^asset_store.AssetStore,
}

FPS :: 60
MILLISECS_PER_FRAME :: 1000 / FPS
WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600



init_engine :: proc () -> (^Game, bool) {
    if sdl.Init(sdl.INIT_EVERYTHING) != 0 {
        log.error("Error initializing SDL.")
        return nil, false
    }

    display_mode: sdl.DisplayMode
    if sdl.GetCurrentDisplayMode(0, &display_mode) != 0 {
        log.error("Error getting current display mode.")
        return nil, false
    }

    window := sdl.CreateWindow(
        nil, 
        sdl.WINDOWPOS_CENTERED, 
        sdl.WINDOWPOS_CENTERED, 
        display_mode.w, 
        display_mode.h,
        sdl.WINDOW_BORDERLESS
    )

    if window == nil {
        log.error("Error creating SDL window.")
        return nil, false
    }

    renderer := sdl.CreateRenderer(
        window,
        -1,
        sdl.RENDERER_ACCELERATED | sdl.RENDERER_PRESENTVSYNC,
    )

    if renderer == nil {
        log.error("Error creating SDL renderer.")
        return nil, false
    }

    sdl.SetWindowFullscreen(window, sdl.WINDOW_FULLSCREEN_DESKTOP)

    game_registry := ecs.init_registry(renderer)
    asset_store := asset_store.init_asset_store()
    game = Game{
        window = window,
        renderer = renderer,
        running = true,
        millisecs_previous_frame = 0,
        window_width = display_mode.w,
        window_height = display_mode.h,
        registry = game_registry,
        asset_store = asset_store,
    }

    log.debug("Game initialized.")

    return &game, true
}

destroy :: proc () {
    log.debug("Destroying game.")
    ecs.destroy_registry(game.registry)
    asset_store.clear_asset_store(game.asset_store)
    sdl.DestroyRenderer(game.renderer)
    sdl.DestroyWindow(game.window)
    sdl.Quit()
    free_all()
    log.debug("Game destroyed.")
}

process_input :: proc () {
    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
            case .QUIT:
                game.running = false
            case .KEYDOWN:
                if event.key.keysym.sym == .ESCAPE {
                    game.running = false
                }
        }
    }
}

update :: proc () {
    time_to_wait := MILLISECS_PER_FRAME - (sdl.GetTicks() - game.millisecs_previous_frame)
    if time_to_wait > 0 && time_to_wait <= MILLISECS_PER_FRAME {
        sdl.Delay(time_to_wait)
    }
    // log.debugf("FPS: %f", 1.0 / (f32(sdl.GetTicks() - game.millisecs_previous_frame) / 1000.0))
    dt := f32(sdl.GetTicks() - game.millisecs_previous_frame) / 1000.0
    game.millisecs_previous_frame = sdl.GetTicks()

    ecs.run_systems(game.registry, game.asset_store, dt)
    ecs.update_registry(game.registry)
}

render :: proc () {
    sdl.SetRenderDrawColor(game.renderer, 21, 21, 21, 255)
    sdl.RenderClear(game.renderer)

    ecs.run_render_systems(game.registry, game.asset_store)
    
    sdl.RenderPresent(game.renderer)
}