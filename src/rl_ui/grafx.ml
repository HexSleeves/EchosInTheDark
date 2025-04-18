open Raylib
module R = Renderer
module T = Rl_core.Map.Tile

(* Get glyph and color for a tile *)
let[@warning "-11"] tile_glyph_and_color (tile : T.t) : string * Color.t =
  match tile with
  | T.Wall -> ("#", Color.gray)
  | T.Floor -> (".", Color.lightgray)
  | T.Stairs_up -> ("<", Color.gold)
  | T.Stairs_down -> (">", Color.orange)
  | _ ->
      Printf.printf "Warning: Unhandled tile type encountered\n";
      ("?", Color.red)

(* Map grid (tile) position to screen position using FontConfig *)
let grid_to_screen (x, y) =
  Raylib.Vector2.create
    (float_of_int x *. float_of_int R.tile_width)
    (float_of_int y *. float_of_int R.tile_height)

let render_cell glyph color (fc : R.font_config) (x, y) =
  let font_size = float_of_int fc.font_size in
  let glyph_size = measure_text_ex fc.font glyph font_size 0. in

  let offset =
    Vector2.create
      ((float_of_int R.tile_width -. Vector2.x glyph_size) /. 2.)
      ((float_of_int R.tile_height -. Vector2.y glyph_size) /. 2.)
  in

  let spacing = 0. in
  let screen_pos = grid_to_screen (x, y) in
  let centered_pos = Vector2.add screen_pos offset in

  (* Font, Text, Position, Font-size, Spacing, Color *)
  draw_text_ex fc.font glyph centered_pos font_size spacing color
