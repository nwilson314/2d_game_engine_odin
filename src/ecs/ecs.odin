package ecs

import "core:log"


component_type_map := make(map[typeid]ComponentType)

Entity :: struct {
    id: u64,
}

ComponentPool :: union {
    ^[dynamic]Transform,
    ^[dynamic]RigidBody,
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

init_registry :: proc() -> ^Registry {
    log.debug("Creating registry")
    registry := new(Registry)
    registry.num_entities = 0
    registry.entities_to_add = make(map[u64]Entity)
    registry.entities_to_remove = make(map[u64]Entity)
    registry.component_pools = make([]ComponentPool, ComponentType.Count)
    

    for i in 0 ..< int(ComponentType.Count) {
        switch ComponentType(i) {
            case ComponentType.Transform:
                registry.component_pools[i] = new([dynamic]Transform)
                component_type_map[typeid_of(Transform)] = ComponentType.Transform
            case ComponentType.RigidBody:
                registry.component_pools[i] = new([dynamic]RigidBody)
                component_type_map[typeid_of(RigidBody)] = ComponentType.RigidBody
            case ComponentType.Count:
                break
        }
    }

    registry.entity_component_signatures = make([dynamic]bit_set[ComponentType])
    log.debugf("Entity component signatures: %v", registry.entity_component_signatures)
    registry.systems = make(map[typeid]^System)

    return registry
}

destroy_registry :: proc(registry: ^Registry) {
    log.debug("Destroying registry")
    free(registry)
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
    log.debugf("Entity component signatures: %v", registry.entity_component_signatures)
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

get_component :: proc(registry: ^Registry, entity: Entity, component: $T) -> T {
    component_type, success := get_component_type_from_type_id(typeid_of(T))
    if !success {
        // Component Type not registered with component
        return nil
    }
    
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


update_registry :: proc(registry: ^Registry) {
    for ent_id in registry.entities_to_add {
        add_entity_to_systems(registry, registry.entities_to_add[ent_id])
        delete_key(&registry.entities_to_add, ent_id)
    }
}


