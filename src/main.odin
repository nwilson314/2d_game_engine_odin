package main

import "core:log"
import glm "core:math/linalg/glsl"
import sdl "vendor:sdl2"
import ecs "ecs"
import engine "engine"
import asset_store "asset_store"


////////////////////////////////
// Game
////////////////////////////////
// Core game logic outside of the ECS and main engine loop

setup :: proc (game: ^engine.Game) {
    log.debug("Setting up game.")

    asset_store.add_texture_to_store(game.asset_store, game.renderer, "tank", "assets/images/tank-panther-right.png")
    asset_store.add_texture_to_store(game.asset_store, game.renderer, "truck", "assets/images/truck-ford-right.png")
    tank := ecs.create_entity(game.registry)
    truck := ecs.create_entity(game.registry)

    ecs.add_component(game.registry, tank, ecs.Transform{
        position = glm.vec2{0.0, 0.0},
        rotation = 0.0,
        scale = glm.vec2{1.0, 1.0},
    })
    ecs.add_component(game.registry, tank, ecs.RigidBody{
        velocity = glm.vec2{40.0, 0.0},
    })
    ecs.add_component(game.registry, tank, ecs.Sprite{
        w = 32,
        h = 32,
        name = "tank",
        src_rect = sdl.Rect{
            x = 0,
            y = 0,
            w = 32,
            h = 32,
        },
    })

    ecs.add_component(game.registry, truck, ecs.Transform{
        position = glm.vec2{0.0, 0.0},
        rotation = 0.0,
        scale = glm.vec2{2.0, 2.0},
    })
    ecs.add_component(game.registry, truck, ecs.RigidBody{
        velocity = glm.vec2{5.0, 5.0},
    })
    ecs.add_component(game.registry, truck, ecs.Sprite{
        w = 32,
        h = 32,
        name = "truck",
        src_rect = sdl.Rect{
            x = 0,
            y = 0,
            w = 32,
            h = 32,
        },
    })
    log.debug("Finished setting up game.")
}

engine_start :: proc (game: ^engine.Game) {
    for game.running {
        engine.process_input()
        engine.update()
        engine.render()
    }

    engine.destroy()
}


main :: proc() {
    context.logger = log.create_console_logger()
    defer log.destroy_console_logger(context.logger)

    game, success := engine.init_engine()
    if !success {
        log.error("Error initializing engine.")
        return
    }
    setup(game)
    engine_start(game)
}