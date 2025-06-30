package main

import "core:fmt"
import log "core:log"
import glm "core:math/linalg/glsl"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

Game :: struct {
    window: ^sdl.Window,
    renderer: ^sdl.Renderer,
    running: bool,
    millisecs_previous_frame: u32,
    window_width: i32,
    window_height: i32,
}

FPS :: 60
MILLISECS_PER_FRAME :: 1000 / FPS

game: Game

player_position: glm.vec2
player_velocity: glm.vec2

init :: proc () {
    context.logger = log.create_console_logger()
    if sdl.Init(sdl.INIT_EVERYTHING) != 0 {
        log.error("Error initializing SDL.")
        return
    }

    display_mode: sdl.DisplayMode
    if sdl.GetCurrentDisplayMode(0, &display_mode) != 0 {
        log.error("Error getting current display mode.")
        return
    }

    window := sdl.CreateWindow(
        nil, 
        sdl.WINDOWPOS_CENTERED, 
        sdl.WINDOWPOS_CENTERED, 
        800, 
        600,
        sdl.WINDOW_BORDERLESS
    )

    if window == nil {
        log.error("Error creating SDL window.")
        return
    }

    renderer := sdl.CreateRenderer(
        window,
        -1,
        sdl.RENDERER_ACCELERATED | sdl.RENDERER_PRESENTVSYNC,
    )

    if renderer == nil {
        log.error("Error creating SDL renderer.")
        return
    }

    sdl.SetWindowFullscreen(window, sdl.WINDOW_FULLSCREEN_DESKTOP)

    game = Game{
        window = window,
        renderer = renderer,
        running = true,
        window_width = 800,
        window_height = 600,
    }

    log.debug("Game initialized.")
}

destroy :: proc () {
    log.debug("Destroying game.")
    log.destroy_console_logger(context.logger)
    sdl.DestroyRenderer(game.renderer)
    sdl.DestroyWindow(game.window)
    sdl.Quit()
}

setup :: proc () {
    player_position = glm.vec2{100, 100}
    player_velocity = glm.vec2{100, 100}
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
    dt := f32(sdl.GetTicks() - game.millisecs_previous_frame) / 1000.0
    game.millisecs_previous_frame = sdl.GetTicks()
    player_position += player_velocity * dt
}

render :: proc () {
    sdl.SetRenderDrawColor(game.renderer, 21, 21, 21, 255)
    sdl.RenderClear(game.renderer)

    surface := img.Load("assets/images/tank-tiger-right.png")
    texture := sdl.CreateTextureFromSurface(game.renderer, surface)
    sdl.FreeSurface(surface)

    dest_rect := sdl.Rect{i32(player_position.x), i32(player_position.y), 32, 32}
    sdl.RenderCopy(game.renderer, texture, nil, &dest_rect)
    sdl.DestroyTexture(texture)
    
    sdl.RenderPresent(game.renderer)
}

main :: proc () {
    init()
    setup()
    for game.running {
        process_input()
        update()
        render()
    }

    destroy()
}