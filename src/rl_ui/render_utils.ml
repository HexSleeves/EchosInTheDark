open Base
open Raylib
module T = Rl_core.Dungeon.Tile

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

(* --- TILESET MAPPING --- *)
let tile_to_sprite_coords = function
  | T.Wall -> (0, 2)
  | T.Floor -> (1, 0)
  | T.Stairs_up -> (18, 2)
  | T.Stairs_down -> (17, 2)
  | T.River -> (1, 0)
  | T.Tree -> (4, 0)
  | T.Door -> (13, 2)
  | _ -> (20, 5)

(* Get glyph and color for a tile *)
let[@warning "-11"] tile_glyph_and_color (tile : T.t) : string * Color.t =
  let color =
    match tile with
    | T.Wall -> Color.gray
    | T.Floor -> Color.lightgray
    | T.Stairs_up -> Color.gold
    | T.Stairs_down -> Color.orange
    | T.Trap -> Color.red
    | T.Secret_door -> Color.purple
    | T.River -> Color.blue
    | T.Chasm -> Color.darkgray
    | _ ->
        Stdlib.Format.eprintf "Warning: Unhandled tile type encountered@.";
        Color.red
  in
  (String.make 1 (Rl_core.Dungeon.Tile.tile_to_glyph tile), color)

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
