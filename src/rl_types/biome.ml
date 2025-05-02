type biome_type =
  | Mine
  | Crystal_Caverns
  | Mushroom_Forest
  | Lava_Chambers
  | Ice_Caves
  | Cursed_Depths
  | Ancient_Ruins
  | Enchanted_Grotto
  | Chasm
  | Toxic_Sludge
  | Gemstone_Vaults
  | Forgotten_Catacombs
  | Underground_Lake
  | Obsidian_Halls
[@@deriving yojson, show, eq, compare, hash, sexp]
