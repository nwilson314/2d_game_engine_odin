package main

import "core:fmt"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

Game :: struct {
    window: ^sdl.Window,
    renderer: ^sdl.Renderer,
    running: bool,
    window_width: i32,
    window_height: i32,
}

game: Game


init :: proc () {
    if sdl.Init(sdl.INIT_EVERYTHING) != 0 {
        fmt.eprintfln("Error initializing SDL.")
        return
    }

    display_mode: sdl.DisplayMode
    if sdl.GetCurrentDisplayMode(0, &display_mode) != 0 {
        fmt.eprintfln("Error getting current display mode.")
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
        fmt.eprintfln("Error creating SDL window.")
        return
    }

    renderer := sdl.CreateRenderer(
        window,
        -1,
        sdl.RENDERER_ACCELERATED | sdl.RENDERER_PRESENTVSYNC,
    )

    if renderer == nil {
        fmt.eprintfln("Error creating SDL renderer.")
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
}

destroy :: proc () {
    sdl.DestroyRenderer(game.renderer)
    sdl.DestroyWindow(game.window)
    sdl.Quit()
}

setup :: proc () {
    
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

}

render :: proc () {
    sdl.SetRenderDrawColor(game.renderer, 21, 21, 21, 255)
    sdl.RenderClear(game.renderer)

    surface := img.Load("assets/images/tank-tiger-right.png")
    texture := sdl.CreateTextureFromSurface(game.renderer, surface)
    sdl.FreeSurface(surface)

    dest_rect := sdl.Rect{10, 10, 32, 32}
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