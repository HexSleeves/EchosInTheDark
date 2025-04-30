open Base
open Rl_types
open Entities
open Mapgen_types
open Biome (* Biome Types from rl_types *)

let pick_biome ~depth ~cx ~cy ~world_seed =
  match depth with
  | d when d < 3 -> Mine
  | d when d < 6 -> if (cx + cy + world_seed) % 2 = 0 then Frigid else Hot
  | d when d < 9 ->
      if (cx + cy + world_seed) % 2 = 0 then Cursed else Enchanted_Mine
  | _ -> Enchanted_Mine

let algo_for_biome = function
  | Biome.Mine | Biome.Enchanted_Mine -> CA
  | Biome.Cursed -> Rooms
  | Biome.Frigid -> CA
  | Biome.Hot -> Rooms
  | _ -> CA

(* --- Biome-specific entity/feature placement --- *)
let place_biome_features_and_entities ~(biome : Biome.biome_type)
    ~(tiles : Dungeon.Tile.t array) ~(width : int) ~(height : int)
    ~(rng : Random.State.t) : entity_id list =
  match biome with
  | Biome.Mine | Biome.Enchanted_Mine ->
      (* Entity_manager.to_list
        (Ca.place_monsters ~grid:tiles ~width ~height ~rng
           (Entity_manager.create ())) *)
      []
  | Biome.Cursed ->
      (* TODO: Place undead, cursed traps, etc *)
      []
  | Biome.Frigid ->
      (* TODO: Place ice monsters, frozen traps, etc *)
      []
  | Biome.Hot ->
      (* TODO: Place fire monsters, lava pools, etc *)
      []
  | _ -> []
