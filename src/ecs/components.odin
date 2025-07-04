package ecs

import glm "core:math/linalg/glsl"
import sdl "vendor:sdl2"

////////////////////////////////
// Components
////////////////////////////////
// When adding new componets, make sure to:
// 1. Add the component to the ComponentType enum
// 2. Add the component to the component_pools union in ecs.ComponentPool
// 3. Add the component to the component_pools array in ecs.init_registry
// 4. Add the component to the component_type_map in ecs.init_registry
// ORDER MATTERS. The order of the ComponentType enum must match the order of the component_pools array
// created in the ecs.init_registry function.

ComponentType :: enum {
    Transform,
    RigidBody,
    Sprite,
    Count,
}

Transform :: struct {
    position: glm.vec2,
    rotation: f64,
    scale: glm.vec2,
}

RigidBody :: struct {
    velocity: glm.vec2,
}

Sprite :: struct {
    w: u32,
    h: u32,
    z_index: u32,
    name: string,
    src_rect: sdl.Rect,
}