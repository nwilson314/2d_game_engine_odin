package main


import "core:log"
import glm "core:math/linalg/glsl"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import ecs "ecs"


Game :: struct {
    window: ^sdl.Window,
    renderer: ^sdl.Renderer,
    running: bool,
    millisecs_previous_frame: u32,
    window_width: i32,
    window_height: i32,
    registry: ^ecs.Registry,
}

FPS :: 60
MILLISECS_PER_FRAME :: 1000 / FPS

game: Game

init :: proc () {
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

    game_registry := ecs.init_registry()
    game = Game{
        window = window,
        renderer = renderer,
        running = true,
        millisecs_previous_frame = 0,
        window_width = 800,
        window_height = 600,
        registry = game_registry,
    }

    log.debug("Game initialized.")
}

destroy :: proc () {
    log.debug("Destroying game.")
    ecs.destroy_registry(game.registry)
    sdl.DestroyRenderer(game.renderer)
    sdl.DestroyWindow(game.window)
    sdl.Quit()
    free_all()
    log.debug("Game destroyed.")
}

setup :: proc () {
    log.debug("Setting up game.")
    tank := ecs.create_entity(game.registry)
    truck := ecs.create_entity(game.registry)

    ecs.add_component(game.registry, tank, ecs.Transform{
        position = glm.vec2{0.0, 0.0},
        rotation = 0.0,
        scale = glm.vec2{1.0, 1.0},
    })
    ecs.add_component(game.registry, tank, ecs.RigidBody{
        velocity = glm.vec2{0.0, 0.0},
    })
    ecs.add_component(game.registry, truck, ecs.Transform{
        position = glm.vec2{0.0, 0.0},
        rotation = 0.0,
        scale = glm.vec2{1.0, 1.0},
    })
    ecs.add_component(game.registry, truck, ecs.RigidBody{
        velocity = glm.vec2{0.0, 0.0},
    })
    log.debug("Finished setting up game.")
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
}

render :: proc () {
    sdl.SetRenderDrawColor(game.renderer, 21, 21, 21, 255)
    sdl.RenderClear(game.renderer)
    
    sdl.RenderPresent(game.renderer)
}

main :: proc () {
    context.logger = log.create_console_logger()
    defer log.destroy_console_logger(context.logger)

    init()
    setup()
    for game.running {
        process_input()
        update()
        render()
    }

    destroy()
}