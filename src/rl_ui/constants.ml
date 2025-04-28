let font_size = 20
let font_path = "resources/fonts/FiraMono-Regular.ttf"

(* Dimensions for UI elements *)
let log_height = 60
let stats_bar_width_min = 200
let stats_bar_width_frac = 0.2

(* Tileset *)
let tile_width = 8
let tile_height = 8
let tile_render_size = 20
let tileset_path = "resources/tiles/classic_roguelike_pico8.png"

(* Render Mode *)
type render_mode = Tiles | Ascii

(* Mutable render mode that can be toggled at runtime *)
let render_mode_ref = ref Tiles

(* Functions to get and toggle the render mode *)
let render_mode () = !render_mode_ref

let toggle_render_mode () =
  render_mode_ref :=
    match !render_mode_ref with Ascii -> Tiles | Tiles -> Ascii

(* Get render mode as string for display *)
let render_mode_to_string mode =
  match mode with Ascii -> "ASCII" | Tiles -> "Tiles"
