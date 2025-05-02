open Base
open Rl_types
open Worldgen_types

(* Helper: Map noise value and depth to a biome *)
let pick_biome ~depth ~x ~y ~world_seed =
  let rng = Random.State.make [| world_seed |] in
  let noise = Worldgen_utils.get_noise_value rng x y in
  match depth with
  | d when d < 3 ->
      if Float.(noise < 0.15) then BiomeType.Crystal_Caverns
      else if Float.(noise < 0.3) then BiomeType.Mushroom_Forest
      else if Float.(noise < 0.45) then BiomeType.Ancient_Ruins
      else if Float.(noise < 0.6) then BiomeType.Mine
      else if Float.(noise < 0.75) then BiomeType.Underground_Lake
      else if Float.(noise < 0.9) then BiomeType.Enchanted_Grotto
      else BiomeType.Gemstone_Vaults
  | d when d < 6 ->
      if Float.(noise < 0.15) then BiomeType.Ice_Caves
      else if Float.(noise < 0.3) then BiomeType.Cursed_Depths
      else if Float.(noise < 0.45) then BiomeType.Chasm
      else if Float.(noise < 0.6) then BiomeType.Ancient_Ruins
      else if Float.(noise < 0.75) then BiomeType.Mushroom_Forest
      else if Float.(noise < 0.9) then BiomeType.Mine
      else BiomeType.Gemstone_Vaults
  | _ ->
      if Float.(noise < 0.1) then BiomeType.Lava_Chambers
      else if Float.(noise < 0.2) then BiomeType.Obsidian_Halls
      else if Float.(noise < 0.35) then BiomeType.Cursed_Depths
      else if Float.(noise < 0.5) then BiomeType.Forgotten_Catacombs
      else if Float.(noise < 0.65) then BiomeType.Chasm
      else if Float.(noise < 0.8) then BiomeType.Toxic_Sludge
      else if Float.(noise < 0.9) then BiomeType.Underground_Lake
      else BiomeType.Gemstone_Vaults

let algo_for_biome = function
  | BiomeType.Mine | BiomeType.Crystal_Caverns | BiomeType.Mushroom_Forest
  | BiomeType.Ancient_Ruins | BiomeType.Enchanted_Grotto
  | BiomeType.Gemstone_Vaults ->
      CA
  | BiomeType.Lava_Chambers | BiomeType.Obsidian_Halls | BiomeType.Chasm
  | BiomeType.Toxic_Sludge ->
      Rooms
  | BiomeType.Ice_Caves -> CA
  | BiomeType.Cursed_Depths | BiomeType.Forgotten_Catacombs -> Rooms
  | BiomeType.Underground_Lake -> CA

(* --- Biome-specific entity/feature placement --- *)
let place_biome_features_and_entities ~(biome : BiomeType.biome_type)
    ~(tiles : Dungeon.Tile.t array) ~(width : int) ~(height : int)
    ~(rng : Random.State.t) : int list =
  match biome with
  | BiomeType.Mine | BiomeType.Crystal_Caverns | BiomeType.Mushroom_Forest
  | BiomeType.Ancient_Ruins | BiomeType.Enchanted_Grotto
  | BiomeType.Gemstone_Vaults ->
      (* TODO: Place biome-specific entities/features *)
      []
  | BiomeType.Lava_Chambers | BiomeType.Obsidian_Halls ->
      (* TODO: Place fire/lava/obsidian features *)
      []
  | BiomeType.Ice_Caves ->
      (* TODO: Place ice/frost features *)
      []
  | BiomeType.Cursed_Depths | BiomeType.Forgotten_Catacombs ->
      (* TODO: Place undead/cursed features *)
      []
  | BiomeType.Chasm ->
      (* TODO: Place chasm hazards *)
      []
  | BiomeType.Toxic_Sludge ->
      (* TODO: Place toxic/mutant features *)
      []
  | BiomeType.Underground_Lake ->
      (* TODO: Place aquatic features *)
      []
