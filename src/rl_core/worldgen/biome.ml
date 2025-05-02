open Base
open Rl_types
open Worldgen_types
open BiomeType

let pick_biome ~depth ~cx ~cy ~world_seed =
  match depth with
  | d when d < 3 -> Mine
  | d when d < 6 -> if (cx + cy + world_seed) % 2 = 0 then Frigid else Hot
  | d when d < 9 ->
      if (cx + cy + world_seed) % 2 = 0 then Cursed else Enchanted_Mine
  | _ -> Enchanted_Mine

let algo_for_biome = function
  | BiomeType.Mine | BiomeType.Enchanted_Mine -> CA
  | BiomeType.Cursed -> Rooms
  | BiomeType.Frigid -> CA
  | BiomeType.Hot -> Rooms
  | _ -> CA

(* --- Biome-specific entity/feature placement --- *)
let place_biome_features_and_entities ~(biome : BiomeType.biome_type)
    ~(tiles : Dungeon.Tile.t array) ~(width : int) ~(height : int)
    ~(rng : Random.State.t) : int list =
  match biome with
  | BiomeType.Mine | BiomeType.Enchanted_Mine ->
      (* Entity_manager.to_list
        (Ca.place_monsters ~grid:tiles ~width ~height ~rng
           (Entity_manager.create ())) *)
      []
  | BiomeType.Cursed ->
      (* TODO: Place undead, cursed traps, etc *)
      []
  | BiomeType.Frigid ->
      (* TODO: Place ice monsters, frozen traps, etc *)
      []
  | BiomeType.Hot ->
      (* TODO: Place fire monsters, lava pools, etc *)
      []
  | _ -> []
