open Base
open Types
open Entities
open Mapgen_types

let pick_biome ~depth ~cx ~cy ~world_seed =
  match depth with
  | d when d < 3 -> Mine
  | d when d < 6 -> if (cx + cy + world_seed) % 2 = 0 then Frigid else Hot
  | d when d < 9 ->
      if (cx + cy + world_seed) % 2 = 0 then Cursed else Enchanted_Mine
  | _ -> Enchanted_Mine

let algo_for_biome = function
  | Types.Mine | Types.Enchanted_Mine -> CA
  | Types.Cursed -> Rooms
  | Types.Frigid -> CA
  | Types.Hot -> Rooms
  | _ -> CA

(* --- Biome-specific entity/feature placement --- *)
let place_biome_features_and_entities ~(biome : Types.biome_type)
    ~(tiles : Dungeon.Tile.t array) ~(width : int) ~(height : int)
    ~(rng : Random.State.t) : entity_id list =
  match biome with
  | Types.Mine | Types.Enchanted_Mine ->
      (* Entity_manager.to_list
        (Ca.place_monsters ~grid:tiles ~width ~height ~rng
           (Entity_manager.create ())) *)
      []
  | Types.Cursed ->
      (* TODO: Place undead, cursed traps, etc *)
      []
  | Types.Frigid ->
      (* TODO: Place ice monsters, frozen traps, etc *)
      []
  | Types.Hot ->
      (* TODO: Place fire monsters, lava pools, etc *)
      []
  | _ -> []
