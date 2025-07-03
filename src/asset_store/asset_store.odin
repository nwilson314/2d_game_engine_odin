package asset_store

import "core:strings"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"


AssetStore :: struct {
    textures: map[string]^sdl.Texture,
}

init_asset_store :: proc() -> ^AssetStore {
    asset_store := new(AssetStore)
    asset_store.textures = make(map[string]^sdl.Texture)
    return asset_store
}

clear_asset_store :: proc(asset_store: ^AssetStore) {
    for texture_name, texture in asset_store.textures {
        sdl.DestroyTexture(texture)
        delete_key(&asset_store.textures, texture_name)
    }
    free(asset_store)
}

add_texture_to_store :: proc(asset_store: ^AssetStore, renderer: ^sdl.Renderer, texture_name: string, file_path: string) {
    surface := img.Load(strings.clone_to_cstring(file_path))
    texture := sdl.CreateTextureFromSurface(renderer, surface)
    asset_store.textures[texture_name] = texture
    sdl.FreeSurface(surface)
}

get_texture_from_store :: proc(asset_store: ^AssetStore, texture_name: string) -> ^sdl.Texture {
    return asset_store.textures[texture_name]
}