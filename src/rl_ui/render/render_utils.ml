open Base
open Raylib
open Dungeon

(* Utility: Get set of occupied positions from a list of entities *)
module PosSet = struct
  module T = struct
    type t = int * int [@@deriving compare, sexp]
  end

  include T
  include Comparator.Make (T)
end

(* Map grid (tile) position to screen position using FontConfig *)
let grid_to_screen ~(tile_render_size : Raylib.Vector2.t) (loc : Rl_types.Loc.t)
    =
  Raylib.Vector2.create
    (Float.of_int loc.x *. Raylib.Vector2.x tile_render_size)
    (Float.of_int loc.y *. Raylib.Vector2.y tile_render_size)

let screen_to_grid ~(tile_render_size : Raylib.Vector2.t)
    (vec : Raylib.Vector2.t) =
  Rl_types.Loc.make
    (Float.to_int (Raylib.Vector2.x vec /. Raylib.Vector2.x tile_render_size))
    (Float.to_int (Raylib.Vector2.y vec /. Raylib.Vector2.y tile_render_size))

let occupied_positions (entities : int list) : Set.M(PosSet).t =
  List.fold entities
    ~init:(Set.empty (module PosSet))
    ~f:(fun acc entity ->
      let pos = Components.Position.get_exn entity in
      Set.add acc (pos.world_pos.x, pos.world_pos.y))

(* Get glyph and color for a tile *)
let[@warning "-11"] tile_glyph_and_color (tile : Tile.t) : string * Color.t =
  let color = Tile.tile_to_color tile in
  (String.make 1 (Tile.tile_to_glyph tile), color)

(* Get glyph for an entity *)
let entity_glyph_and_color (entity : int) : string * Color.t =
  let glyph, color =
    ( (match Components.Kind.get entity with
      | Some Player -> '@'
      | Some Creature -> 'C'
      | Some Item -> 'I'
      | Some Corpse -> 'X'
      | None -> failwith "Entity has no kind")
      |> String.make 1,
      match Components.Kind.get entity with
      | Some Player -> Color.white
      | Some Creature -> Color.red
      | Some Item -> Color.yellow
      | Some Corpse -> Color.gray
      | None -> failwith "Entity has no kind" )
  in

  (glyph, color)

let entity_to_sprite_coords (entity_id : int) =
  match Components.Kind.get entity_id with
  | Some Item -> (5, 0)
  | Some Corpse -> (6, 0)
  | Some Player -> (0, 3) (* Example: player tile *)
  | Some Creature -> (
      match Components.Species.get entity_id with
      | Some species -> (
          match species with
          | `Rat -> (5, 3)
          | `Goblin -> (2, 0)
          | `Kobold -> (3, 0)
          | `Spider -> (4, 0)
          | _ -> Render_constants.unknown_tile_sprite_coords)
      | None -> Render_constants.unknown_tile_sprite_coords)
  | None -> failwith "Entity has no kind"

let draw_font_text ~font ~font_size ~color ~text ~pos_x ~pos_y =
  Raylib.draw_text_ex font text
    (Raylib.Vector2.create pos_x pos_y)
    font_size 0. color

let draw_texture_ex ~texture ~pos ~origin ~col ~row
    ~(tile_render_size : Raylib.Vector2.t) ~(is_visible : bool)
    ~(is_seen : bool) =
  let tile_width = Render_constants.tile_width in
  let tile_height = Render_constants.tile_height in

  let src =
    Raylib.Rectangle.create
      (Float.of_int (col * tile_width))
      (Float.of_int (row * tile_height))
      (Float.of_int tile_width) (Float.of_int tile_height)
  in
  let dest =
    let base_pos = grid_to_screen ~tile_render_size pos in
    Raylib.Vector2.add base_pos origin
  in
  let dest_rect =
    Raylib.Rectangle.create (Raylib.Vector2.x dest) (Raylib.Vector2.y dest)
      (Raylib.Vector2.x tile_render_size)
      (Raylib.Vector2.y tile_render_size)
  in

  let color =
    match (is_visible, is_seen) with
    | true, _ -> Color.white
    | _, true -> Color.gray
    | false, false -> Color.black
  in

  let rotation = 0. in
  let img_origin = Raylib.Vector2.create 0. 0. in
  Raylib.draw_texture_pro texture src dest_rect img_origin rotation color
