package ecs

import "core:log"


Entity :: struct {
    id: u64,
}

ComponentPool :: union {
    ^[dynamic]Transform,
    ^[dynamic]Velocity,
}

System :: struct {
    component_signature: bit_set[ComponentType],
    entities: [dynamic]Entity,
    update: proc(registry: ^Registry, system: ^System),
}

Registry :: struct{
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
    systems: map[typeid]^System,
}

// world := World {
//     num_entities = 0,
//     component_pools = {
//         new([dynamic]Transform),
//         new([dynamic]Velocity),
//     }
// }

////////////////////////////////
// Components
////////////////////////////////

add_component :: proc(registry: ^Registry, entity: Entity, component_type: ComponentType, component: $T) {
    // Get component pool for component type
    component_pool := registry.component_pools[component_type].(^[dynamic]T)
    if entity.id >= len(component_pool) {
        resize(component_pool, entity.id + 1)
    }
    component_pool[entity.id] = component

    registry.entity_component_signatures[entity.id] |= bit_set[ComponentType]{component_type}
}

remove_component :: proc(registry: ^Registry, entity: Entity, component_type: ComponentType, component: $T) {
    component_pool := registry.component_pools[component_type].(^[dynamic]T)
    component_pool[entity.id] = nil
    registry.entity_component_signatures[entity.id] &= ~bit_set[ComponentType]{component_type}
}

has_component :: proc(registry: ^Registry, entity: Entity, component_type: ComponentType) -> bool {
    return registry.entity_component_signatures[entity.id] & bit_set[ComponentType]{component_type} != bit_set[ComponentType]{component_type}
}

get_component :: proc(registry: ^Registry, entity: Entity, component_type: ComponentType, component: $T) -> T {
    component_pool := registry.component_pools[component_type].(^[dynamic]T)
    return component_pool[entity.id]
}

////////////////////////////////
// Systems
////////////////////////////////

add_system :: proc(registry: ^Registry, system: ^System) {
    id := typeid_of(type_of(system))
    registry.systems[id] = system
}

remove_system :: proc(registry: ^Registry, system: ^System) {
    id := typeid_of(type_of(system))
    delete_key(&registry.systems, id)
}

has_system :: proc(registry: ^Registry, system: ^System) -> bool {
    id := typeid_of(type_of(system))
    return id in registry.systems
}

add_entity_to_systems :: proc(registry: ^Registry, entity: Entity) {
    entity_component_signature := registry.entity_component_signatures[entity.id]

    for type_id, system in registry.systems {
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
    ent_id := registry.num_entities + 1
    registry.num_entities += 1
    append(&registry.entity_component_signatures, bit_set[ComponentType]{})
    entity := Entity{id = ent_id}

    registry.entities_to_add[ent_id] = entity

    log.debug("Created entity with id: %", ent_id)
    return entity
}

remove_entity :: proc(registry: ^Registry, entity: Entity) {
    
}


update_registry :: proc(registry: ^Registry) {
    for ent_id in registry.entities_to_add {
        log.debug("Adding entity with id: %", ent_id)
    }
}


