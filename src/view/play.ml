let render (state : State.t) =
  let open Raylib in
  let backend = state.backend in

  (* Configuration for rendering *)
  let font_size = 20.0 in
  let grid_size = font_size *. 0.8 in
  (* Scale grid relative to font size *)
  let x_offset = grid_size *. 0.5 in
  (* Center text in grid cells *)
  let y_offset = 0.0 in
  (* Adjust if needed for vertical centering *)

  let len = measure_text (Int.to_string (get_fps ()) ^ " FPS") 20 in
  draw_fps (get_screen_width () - len) (get_screen_height () - 20);

  (* Render map tiles *)
  Array.iteri
    (fun i t ->
      let tile = match t with Tile.Wall -> "#" | Tile.Floor -> "." in
      let x = i mod backend.map.width |> Int.to_float in
      let y = i / backend.map.width |> Int.to_float in
      let x = (x *. grid_size) +. x_offset in
      let y = (y *. grid_size) +. y_offset in
      draw_text_ex state.font tile (Vector2.create x y) font_size 0. Color.white)
    backend.map.map

let handle_event state = state
