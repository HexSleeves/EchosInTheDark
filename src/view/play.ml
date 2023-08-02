let render (state : State.t) =
  let open Raylib in
  let backend = state.backend in

  let len = measure_text (Int.to_string (get_fps ()) ^ " FPS") 20 in
  draw_fps (get_screen_width () - len) (get_screen_height () - 20);

  (* let x, y = State.get_player_pos state in
     let x = x |> Int.to_float in
     let y = y |> Int.to_float in
     let x = (x *. 12.0) +. 6.0 in
     let y = (y *. 12.0) +. 6.0 in
     draw_text "@" (Int.of_float x) (Int.of_float y) 12 Color.red; *)
  Array.iteri
    (fun i t ->
      let tile = match t with Tile.Wall -> "#" | Tile.Floor -> "." in
      let x = i mod backend.map.width |> Int.to_float in
      let y = i / backend.map.width |> Int.to_float in
      let x = (x *. 12.0) +. 6.0 in
      let y = (y *. 12.0) +. 0.0 in
      draw_text_ex state.font tile (Vector2.create x y) 12. 0. Color.white)
    backend.map.map

let handle_event state = state
