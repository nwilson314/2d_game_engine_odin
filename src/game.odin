package main

import "core:log"
import glm "core:math/linalg/glsl"
import ecs "ecs"

////////////////////////////////
// Game
////////////////////////////////
// Core game logic outside of the ECS and main engine loop

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
        velocity = glm.vec2{5.0, 0.0},
    })
    ecs.add_component(game.registry, tank, ecs.Sprite{
        w = 64,
        h = 64,
    })
    log.debug("Finished setting up game.")
}