let font_size = 20
let font_path = "resources/fonts/FiraMono-Regular.ttf"

(* Dimensions for UI elements *)
let margin = 8
let log_height = 120
let stats_bar_width_min = 220
let stats_bar_width_frac = 0.24

(* Tileset *)
let tile_width = 8
let tile_height = 8
let tile_render_size = Raylib.Vector2.create 20. 20.
let tileset_path = "resources/tiles/classic_roguelike_pico8.png"

(* Render Mode Type Definition *)
type render_mode = Tiles | Ascii [@@deriving sexp, show]

(* Default or fallback sprite coordinates *)
let unknown_tile_sprite_coords = (20, 5)

(* Color palette for dark/gold theme *)
let color_dark_bg = Raylib.Color.create 18 18 20 255
let color_gold = Raylib.Color.create 212 175 55 255
