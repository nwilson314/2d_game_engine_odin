package ecs

import "core:log"
import sdl "vendor:sdl2"
import asset_store "../asset_store"

component_type_map := make(map[typeid]ComponentType)
system_type_map := make(map[u64]SystemType)
system_id_counter: u64 = 0

Entity :: struct {
    id: u64,
}

ComponentPool :: union {
    ^[dynamic]Transform,
    ^[dynamic]RigidBody,
    ^[dynamic]Sprite,
}

System :: struct {
    id: u64,
    component_signature: bit_set[ComponentType],
    entities: [dynamic]Entity,
    update: proc(registry: ^Registry, asset_store: ^asset_store.AssetStore, system: ^System, dt: f32),
}

Registry :: struct{
    renderer: ^sdl.Renderer,
    num_entities: u64,
    entities_to_add: map[u64]Entity,
    entities_to_remove: map[u64]Entity,

    // Array of component pools, each pool contains all the data for a certain component type.
    // The index of the pool in the array is the component type.
    // The index of the component in the pool is the entity id.
    component_pools: []ComponentPool,

    // Array of bit sets, each bit set contains the component types for an entity.
    // The index of the bit set in the array is the entity id.
    entity_component_signatures: [dynamic]bit_set[ComponentType],
    systems: map[SystemType]^System,
}

init_registry :: proc(renderer: ^sdl.Renderer) -> ^Registry {
    log.debug("Creating registry")

    // Initialize registry
    registry := new(Registry)
    registry.renderer = renderer
    registry.num_entities = 0
    registry.entities_to_add = make(map[u64]Entity)
    registry.entities_to_remove = make(map[u64]Entity)
    registry.component_pools = make([]ComponentPool, ComponentType.Count)
    
    // Initialize component pools
    for i in 0 ..< int(ComponentType.Count) {
        switch ComponentType(i) {
            case ComponentType.Transform:
                registry.component_pools[i] = new([dynamic]Transform)
                component_type_map[typeid_of(Transform)] = ComponentType.Transform
            case ComponentType.RigidBody:
                registry.component_pools[i] = new([dynamic]RigidBody)
                component_type_map[typeid_of(RigidBody)] = ComponentType.RigidBody
            case ComponentType.Sprite:
                registry.component_pools[i] = new([dynamic]Sprite)
                component_type_map[typeid_of(Sprite)] = ComponentType.Sprite
            case ComponentType.Count:
                break
        }
    }

    registry.entity_component_signatures = make([dynamic]bit_set[ComponentType])
    
    // Initialize systems
    registry.systems = make(map[SystemType]^System)

    for i in 0 ..< int(SystemType.Count) {
        switch SystemType(i) {
            case SystemType.Movement:
                movement_system := new(System)
                movement_system.id = system_id_counter
                system_id_counter += 1
                movement_system.component_signature = bit_set[ComponentType]{ComponentType.Transform, ComponentType.RigidBody}
                movement_system.entities = make([dynamic]Entity)
                movement_system.update = MovementSystem
                registry.systems[SystemType.Movement] = movement_system

                system_type_map[movement_system.id] = SystemType.Movement
            case SystemType.Render:
                render_system := new(System)
                render_system.id = system_id_counter
                system_id_counter += 1
                render_system.component_signature = bit_set[ComponentType]{ComponentType.Transform, ComponentType.Sprite}
                render_system.entities = make([dynamic]Entity)
                render_system.update = RenderSystem
                registry.systems[SystemType.Render] = render_system

                system_type_map[render_system.id] = SystemType.Render
            case SystemType.Count:
                break
        }
    }

    return registry
}

destroy_registry :: proc(registry: ^Registry) {
    log.debug("Destroying registry")
    free(registry)
}

update_registry :: proc(registry: ^Registry) {
    for ent_id in registry.entities_to_add {
        add_entity_to_systems(registry, registry.entities_to_add[ent_id])
        delete_key(&registry.entities_to_add, ent_id)
    }
}


run_systems :: proc(registry: ^Registry, asset_store: ^asset_store.AssetStore, dt: f32) {
    registry.systems[SystemType.Movement].update(registry, asset_store, registry.systems[SystemType.Movement], dt)
}

run_render_systems :: proc(registry: ^Registry, asset_store: ^asset_store.AssetStore) {
    registry.systems[SystemType.Render].update(registry, asset_store, registry.systems[SystemType.Render], 0.0)
}

////////////////////////////////
// Components
////////////////////////////////

get_component_type_from_type_id :: proc(type_id: typeid) -> (ComponentType, bool) {
    if !(type_id in component_type_map) {
        log.errorf("Component type_id %s not registered to component.", type_id)
        return ComponentType.Count, false
    }
    return component_type_map[type_id], true
}

add_component :: proc(registry: ^Registry, entity: Entity, component: $T) {
    component_type, success := get_component_type_from_type_id(typeid_of(T))
    if !success {
        // Component Type not registered with component
        return
    }

    // Get component pool for component type
    component_pool := registry.component_pools[component_type].(^[dynamic]T)
    if entity.id >= u64(len(component_pool)) {
        resize(component_pool, entity.id + 1)
    }
    component_pool[entity.id] = component

    registry.entity_component_signatures[entity.id] |= bit_set[ComponentType]{component_type}
}

remove_component :: proc(registry: ^Registry, entity: Entity, component: $T) {
    component_type, success := get_component_type_from_type_id(typeid_of(T))
    if !success {
        // Component Type not registered with component
        return
    }

    component_pool := registry.component_pools[component_type].(^[dynamic]T)
    component_pool[entity.id] = {}
    registry.entity_component_signatures[entity.id] &= ~bit_set[ComponentType]{component_type}
}

has_component :: proc(registry: ^Registry, entity: Entity, component: $T) -> bool {
    component_type, success := get_component_type_from_type_id(typeid_of(T))
    if !success {
        // Component Type not registered with component
        return false
    }
    ent_sig := registry.entity_component_signatures[entity.id]
    return ent_sig & bit_set[ComponentType]{component_type} == bit_set[ComponentType]{component_type}
}

get_component :: proc(registry: ^Registry, entity: Entity, component: $T) -> ^T {
    component_type, success := get_component_type_from_type_id(typeid_of(T))
    if !success {
        // Component Type not registered with component
        return nil
    }
    
    component_pool := registry.component_pools[component_type].(^[dynamic]T)
    return &component_pool[entity.id]
}

////////////////////////////////
// Systems
////////////////////////////////

add_system :: proc(registry: ^Registry, system: ^System) {
    system_type := system_type_map[system.id]
    registry.systems[system_type] = system
}

remove_system :: proc(registry: ^Registry, system: ^System) {
    system_type := system_type_map[system.id]
    delete_key(&registry.systems, system_type)
}

has_system :: proc(registry: ^Registry, system: ^System) -> bool {
    system_type := system_type_map[system.id]
    return system_type in registry.systems
}

add_entity_to_systems :: proc(registry: ^Registry, entity: Entity) {
    entity_component_signature := registry.entity_component_signatures[entity.id]

    for system_type, system in registry.systems {
        system_signature := system.component_signature
        
        is_interested := entity_component_signature & system_signature == system_signature
        if is_interested {
            add_entity_to_system(system, entity)
        }
    }
}

add_entity_to_system :: proc(system: ^System, entity: Entity) {
    append(&system.entities, entity)
}

remove_entity_from_system :: proc(system: ^System, entity: Entity) {
    for i in 0 ..< len(system.entities) {
        if system.entities[i].id == entity.id {
            unordered_remove(&system.entities, i)
            break
        }
    }
}

////////////////////////////////
// Entities
////////////////////////////////

create_entity :: proc(registry: ^Registry) -> Entity {
    ent_id := registry.num_entities
    registry.num_entities += 1
    append(&registry.entity_component_signatures, bit_set[ComponentType]{})
    entity := Entity{id = ent_id}

    registry.entities_to_add[ent_id] = entity

    log.debugf("Created entity with id: %d", ent_id)
    return entity
}

remove_entity :: proc(registry: ^Registry, entity: Entity) {
    
}