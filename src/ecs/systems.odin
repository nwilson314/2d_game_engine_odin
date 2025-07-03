package ecs

import "core:log"
import sdl "vendor:sdl2"
import asset_store "../asset_store"

////////////////////////////////
// Systems
////////////////////////////////
// When adding new systems, make sure to:
// 1. Add the system to the SystemType enum
// 2. Add the system to the systems array in ecs.init_registry
// 3. Add the system to the system_type_map in ecs.init_registry


SystemType :: enum {
    Movement,
    Render,
    Count,
}

MovementSystem :: proc(registry: ^Registry, ast_store: ^asset_store.AssetStore, system: ^System, dt: f32) {
    for entity in system.entities {
        transform := get_component(registry, entity, Transform{})
        rigid_body := get_component(registry, entity, RigidBody{})
        transform.position += rigid_body.velocity * dt
    }
}

RenderSystem :: proc(registry: ^Registry, ast_store: ^asset_store.AssetStore, system: ^System, dt: f32) {
    for entity in system.entities {
        transform := get_component(registry, entity, Transform{})
        sprite := get_component(registry, entity, Sprite{})
        texture := asset_store.get_texture_from_store(ast_store, sprite.name)

        src_rect := sdl.Rect{
            x = 0,
            y = 0,
            w = i32(sprite.w),
            h = i32(sprite.h),
        }

        dst_rect := sdl.Rect{
            x = i32(transform.position.x),
            y = i32(transform.position.y),
            w = i32(f32(sprite.w) * transform.scale.x),
            h = i32(f32(sprite.h) * transform.scale.y),
        }

        sdl.RenderCopyEx(
            registry.renderer,
            texture,
            &src_rect,
            &dst_rect,
            transform.rotation,
            nil,
            sdl.RendererFlip.NONE,
        )
    }
}