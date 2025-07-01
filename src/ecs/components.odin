package ecs

import glm "core:math/linalg/glsl"


ComponentType :: enum {
    Transform,
    Velocity,
    Count,
}

Transform :: struct {
    position: glm.vec2,
    rotation: f32,
    scale: glm.vec2,
}

Velocity :: struct {
    velocity: glm.vec2,
}