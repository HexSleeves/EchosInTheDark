type t =
  | Wall
  | Floor
  | Stairs_up
  | Stairs_down
  | River
  | Chasm
  | Trap
  | Secret_door
  | Unknown
[@@deriving eq, yojson, enum, show]

let is_wall = function Wall -> true | _ -> false
let is_floor = function Floor -> true | _ -> false

let is_walkable = function
  | Wall | Chasm | Trap | Secret_door | River | Stairs_up | Stairs_down -> false
  | _ -> true

let is_trap = function Trap -> true | _ -> false
let is_secret_door = function Secret_door -> true | _ -> false

let tile_to_glyph tile =
  match tile with
  | Floor -> '.'
  | Wall -> '#'
  | River -> '~'
  | Chasm -> '%'
  | Trap -> '!'
  | Stairs_up -> '<'
  | Stairs_down -> '>'
  | Secret_door -> '+'
  | Unknown -> '?'
