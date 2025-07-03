package ecs

import "core:log"
import sdl "vendor:sdl2"

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

MovementSystem :: proc(registry: ^Registry, system: ^System, dt: f32) {
    for entity in system.entities {
        transform := get_component(registry, entity, Transform{})
        rigid_body := get_component(registry, entity, RigidBody{})
        transform.position += rigid_body.velocity * dt
        log.debugf("Entity %d moved to %v", entity.id, transform.position)
    }
}

RenderSystem :: proc(registry: ^Registry, system: ^System, dt: f32) {
    for entity in system.entities {
        transform := get_component(registry, entity, Transform{})
        sprite := get_component(registry, entity, Sprite{})
        log.debugf("Entity %d rendered at %v", entity.id, transform.position)
        obj_rect := sdl.Rect{
            x = i32(transform.position.x),
            y = i32(transform.position.y),
            w = i32(sprite.w),
            h = i32(sprite.h),
        }
        sdl.SetRenderDrawColor(registry.renderer, 255, 255, 255, 255)
        sdl.RenderFillRect(registry.renderer, &obj_rect)
    }
}