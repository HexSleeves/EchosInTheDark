type biome_type =
  | Plains
  | Forest
  | Mountain
  | Water_Body
  | Desert
  | Mine
  | Enchanted_Mine
  | Cursed
  | Frigid
  | Hot
[@@deriving yojson, show, eq, compare, hash, sexp]
