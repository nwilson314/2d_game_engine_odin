package main

import "core:log"
import "core:os"
import "core:strings"
import "core:strconv"
import glm "core:math/linalg/glsl"
import sdl "vendor:sdl2"
import ecs "ecs"
import engine "engine"
import asset_store "asset_store"


////////////////////////////////
// Game
////////////////////////////////
// Core game logic outside of the ECS and main engine loop

TILEMAP_WIDTH :: 10
TILEMAP_HEIGHT :: 3
TILEMAP_TILE_SIZE :: 32
TILEMAP_SCALE :: 2

load_tilemap :: proc (game: ^engine.Game, tilemap_name: string, tilemap_level_filepath: string) {
    log.debugf("Loading tilemap level %s", tilemap_level_filepath)
    data, ok := os.read_entire_file(tilemap_level_filepath)
    if !ok {
        log.errorf("Failed to load tilemap level %s", tilemap_level_filepath)
        return
    }
    defer delete(data)

    it := string(data)
    i := 0
    j := 0
    for line in strings.split_lines_iterator(&it) {
        i = 0
        for tile in strings.split(line, ",") {
            tile_int, ok := strconv.parse_int(tile)
            if !ok {
                log.errorf("Failed to parse tile %s", tile)
                continue
            }
            dest_x := i * TILEMAP_TILE_SIZE
            dest_y := j * TILEMAP_TILE_SIZE
            src_y := (tile_int / TILEMAP_WIDTH) * TILEMAP_TILE_SIZE
            src_x := (tile_int % TILEMAP_WIDTH) * TILEMAP_TILE_SIZE

            log.debugf("Tilemap with tile %d at source: %d, %d", tile_int, src_x, src_y)
            ent := ecs.create_entity(game.registry)
            ecs.add_component(game.registry, ent, ecs.Transform{
                position = glm.vec2{f32(dest_x) * f32(TILEMAP_SCALE), f32(dest_y) * f32(TILEMAP_SCALE)},
                rotation = 0.0,
                scale = glm.vec2{f32(TILEMAP_SCALE), f32(TILEMAP_SCALE)},
            })
            ecs.add_component(game.registry, ent, ecs.Sprite{
                w = TILEMAP_TILE_SIZE,
                h = TILEMAP_TILE_SIZE,
                z_index = 0,
                name = tilemap_name,
                src_rect = sdl.Rect{
                    x = i32(src_x),
                    y = i32(src_y),
                    w = TILEMAP_TILE_SIZE,
                    h = TILEMAP_TILE_SIZE,
                },
            })
            i += 1
        }
        j += 1
    }

}


setup :: proc (game: ^engine.Game) {
    log.debug("Setting up game.")

    asset_store.add_texture_to_store(game.asset_store, game.renderer, "tank", "assets/images/tank-panther-right.png")
    asset_store.add_texture_to_store(game.asset_store, game.renderer, "truck", "assets/images/truck-ford-right.png")
    asset_store.add_texture_to_store(game.asset_store, game.renderer, "chopper", "assets/images/chopper.png")
    asset_store.add_texture_to_store(game.asset_store, game.renderer, "radar", "assets/images/radar.png")
    asset_store.add_texture_to_store(game.asset_store, game.renderer, "jungle", "assets/tilemaps/jungle.png")

    load_tilemap(game, "jungle", "assets/tilemaps/jungle.map")
    chopper := ecs.create_entity(game.registry)
    ecs.add_component(game.registry, chopper, ecs.Transform{
        position = glm.vec2{0.0, 0.0},
        rotation = 0.0,
        scale = glm.vec2{1.0, 1.0},
    })
    ecs.add_component(game.registry, chopper, ecs.RigidBody{
        velocity = glm.vec2{0.0, 0.0},
    })
    ecs.add_component(game.registry, chopper, ecs.Sprite{
        w = 32,
        h = 32,
        z_index = 1,
        name = "chopper",
        src_rect = sdl.Rect{
            x = 0,
            y = 0,
            w = 32,
            h = 32,
        },
    })
    ecs.add_component(game.registry, chopper, ecs.Animation{
        num_frames = 2,
        current_frame = 0,
        frame_speed_rate = 10,
        start_time = sdl.GetTicks(),
        is_loop = true,
    })

    radar := ecs.create_entity(game.registry)
    ecs.add_component(game.registry, radar, ecs.Transform{
        position = glm.vec2{f32(game.window_width - 74), 10},
        rotation = 0.0,
        scale = glm.vec2{1.0, 1.0},
    })
    ecs.add_component(game.registry, radar, ecs.Sprite{
        w = 64,
        h = 64,
        z_index = 1,
        name = "radar",
        src_rect = sdl.Rect{
            x = 0,
            y = 0,
            w = 64,
            h = 64,
        },
    })
    ecs.add_component(game.registry, radar, ecs.Animation{
        num_frames = 8,
        current_frame = 0,
        frame_speed_rate = 8,
        start_time = sdl.GetTicks(),
        is_loop = true,
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