package ecs

import "core:log"
import "core:slice"
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
    Animation,
    Render,
    Count,
}

Renderable :: struct {
    entity: Entity,
    z_index: u32,
    sprite: ^Sprite,
    transform: ^Transform,
}

MovementSystem :: proc(registry: ^Registry, ast_store: ^asset_store.AssetStore, system: ^System, dt: f32) {
    for entity in system.entities {
        transform := get_component(registry, entity, Transform{})
        rigid_body := get_component(registry, entity, RigidBody{})
        transform.position += rigid_body.velocity * dt
    }
}

by_z_index :: proc(a, b: Renderable) -> bool {
    return a.z_index < b.z_index
}

gather_renderable_entities :: proc(registry: ^Registry, system: ^System) -> [dynamic]Renderable {
    renderables: [dynamic]Renderable = {}
    for entity in system.entities {
        sprite := get_component(registry, entity, Sprite{})
        transform := get_component(registry, entity, Transform{})
        append(&renderables, Renderable{entity = entity, z_index = sprite.z_index, sprite = sprite, transform = transform})
    }
    return renderables
}

RenderSystem :: proc(registry: ^Registry, ast_store: ^asset_store.AssetStore, system: ^System, dt: f32) {
    renderable_entities := gather_renderable_entities(registry, system)
    slice.sort_by(renderable_entities[:], by_z_index)

    for entity in renderable_entities {
        sprite := entity.sprite
        transform := entity.transform
        texture := asset_store.get_texture_from_store(ast_store, sprite.name)

        dst_rect := sdl.Rect{
            x = i32(transform.position.x),
            y = i32(transform.position.y),
            w = i32(f32(sprite.w) * transform.scale.x),
            h = i32(f32(sprite.h) * transform.scale.y),
        }

        sdl.RenderCopyEx(
            registry.renderer,
            texture,
            &sprite.src_rect,
            &dst_rect,
            transform.rotation,
            nil,
            sdl.RendererFlip.NONE,
        )
    }
}

AnimationSystem :: proc(registry: ^Registry, ast_store: ^asset_store.AssetStore, system: ^System, dt: f32) {
    for entity in system.entities {
        animation := get_component(registry, entity, Animation{})
        sprite := get_component(registry, entity, Sprite{})

        animation.current_frame = 
        (i32(sdl.GetTicks() - animation.start_time) * 
            (animation.frame_speed_rate) / 1000) % animation.num_frames
        log.debugf("Animation current frame for entity %d: %d", entity.id, animation.current_frame)

        sprite.src_rect.x = animation.current_frame * i32(sprite.w)

    }

}