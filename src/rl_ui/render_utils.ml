open Base
open Raylib
module Tile = Rl_core.Dungeon.Tile

(* Map grid (tile) position to screen position using FontConfig *)
let grid_to_screen (loc : Rl_core.Types.Loc.t) =
  Raylib.Vector2.create
    (Float.of_int loc.x *. Float.of_int Constants.font_size)
    (Float.of_int loc.y *. Float.of_int Constants.font_size)

let screen_to_grid (vec : Vector2.t) =
  Rl_core.Types.Loc.make
    (Float.to_int (Vector2.x vec /. Float.of_int Constants.font_size))
    (Float.to_int (Vector2.y vec /. Float.of_int Constants.font_size))

(* Utility: Get set of occupied positions from a list of entities *)
module PosSet = struct
  module T = struct
    type t = int * int [@@deriving compare, sexp]
  end

  include T
  include Comparator.Make (T)
end

let occupied_positions (entities : Rl_core.Types.Entity.t list) :
    Set.M(PosSet).t =
  List.fold entities
    ~init:(Set.empty (module PosSet))
    ~f:(fun acc e ->
      let base = Rl_core.Types.Entity.get_base e in
      Set.add acc (base.pos.x, base.pos.y))

(* Get glyph and color for a tile *)
let[@warning "-11"] tile_glyph_and_color (tile : Tile.t) : string * Color.t =
  let color = Tile.tile_to_color tile in
  (String.make 1 (Tile.tile_to_glyph tile), color)

(* Get glyph for an entity *)
let entity_glyph_and_color (entity : Rl_core.Types.Entity.t) : string * Color.t
    =
  let base = Rl_core.Types.Entity.get_base entity in
  let color =
    match entity with
    | Rl_core.Types.Entity.Player _ -> Color.white
    | Rl_core.Types.Entity.Creature _ -> Color.red
    | Rl_core.Types.Entity.Item _ -> Color.yellow
    | Rl_core.Types.Entity.Corpse _ -> Color.gray
  in
  (base.glyph, color)

let entity_to_sprite_coords (entity : Rl_core.Types.Entity.t) =
  match entity with
  | Rl_core.Types.Entity.Player _ -> (0, 3) (* Example: player tile *)
  | Rl_core.Types.Entity.Creature (_, data) -> (
      match String.lowercase data.species with
      | "rat" -> (1, 0)
      | "goblin" -> (2, 0)
      | "kobold" -> (3, 0)
      | "giant spider" -> (4, 0)
      | _ -> (20, 5))
  | Rl_core.Types.Entity.Item _ -> (5, 0)
  | Rl_core.Types.Entity.Corpse _ -> (6, 0)
