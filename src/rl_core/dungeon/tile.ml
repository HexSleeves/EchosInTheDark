type t =
  | Wall
  | Floor
  | Stairs_up
  | Stairs_down
  | Water
  | Chasm
  | Trap
  | Secret_door
  | Tree
  | Door
  | Unknown
  | Lava
  | Ice
  | Sludge
  | Obsidian
  | Crystal
  | Fungi
  | Gem
[@@deriving eq, yojson, enum, show]

let is_wall = function Wall -> true | _ -> false
let is_floor = function Floor -> true | _ -> false
let is_walkable = function Wall | Tree | Door -> false | _ -> true
let is_trap = function Trap -> true | _ -> false
let is_secret_door = function Secret_door -> true | _ -> false
let is_opaque = function Wall -> true | _ -> false

let tile_to_glyph tile =
  match tile with
  | Floor -> '.'
  | Wall -> '#'
  | Water -> '~'
  | Chasm -> '%'
  | Trap -> '!'
  | Stairs_up -> '<'
  | Stairs_down -> '>'
  | Secret_door -> '+'
  | Tree -> 'T'
  | Door -> '+'
  | Lava -> 'L'
  | Ice -> '*'
  | Sludge -> 's'
  | Obsidian -> 'O'
  | Crystal -> 'c'
  | Fungi -> 'f'
  | Gem -> 'g'
  | Unknown -> '?'

let tile_to_tileset tile =
  match tile with
  | Wall -> (0, 2)
  | Floor -> (1, 0)
  | Stairs_up -> (18, 2)
  | Stairs_down -> (17, 2)
  | Water -> (1, 0)
  | Tree -> (4, 0)
  | Door -> (13, 2)
  | Trap -> (15, 1)
  | Secret_door -> (19, 1)
  | Chasm -> (3, 2)
  | Lava -> (2, 3)
  | Ice -> (4, 3)
  | Sludge -> (5, 3)
  | Obsidian -> (6, 3)
  | Crystal -> (7, 3)
  | Fungi -> (8, 3)
  | Gem -> (9, 3)
  | _ -> (20, 5)

let tile_to_color tile =
  let open Raylib in
  match tile with
  | Wall -> Color.gray
  | Floor -> Color.lightgray
  | Stairs_up -> Color.gold
  | Stairs_down -> Color.gold
  | Trap -> Color.red
  | Secret_door -> Color.purple
  | Water -> Color.blue
  | Chasm -> Color.darkgray
  | Tree -> Color.green
  | Door -> Color.brown
  | Lava -> Color.orange
  | Ice -> Color.skyblue
  | Sludge -> Color.lime
  | Obsidian -> Color.black
  | Crystal -> Color.skyblue
  | Fungi -> Color.violet
  | Gem -> Color.magenta
  | Unknown -> Color.red
