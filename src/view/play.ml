let render (state : State.t) : State.t option =
  let open Raylib in
  let backend = state.backend in
  let fc = state.font_config in

  let len = measure_text (Int.to_string (get_fps ()) ^ " FPS") fc.font_size in
  draw_fps (get_screen_width () - len) (get_screen_height () - fc.font_size);

  (* Player entity *)
  let player_entity =
    {
      Renderer.glyph = "@";
      color = Color.white;
      pos =
        (let px = Vector2.x state.player_pos |> int_of_float in
         let py = Vector2.y state.player_pos |> int_of_float in
         (px, py));
    }
  in

  (* Render map tiles and entities *)
  Array.iteri
    (fun i t ->
      let x = i mod backend.map.width in
      let y = i / backend.map.width in
      if (x, y) = player_entity.pos then
        let glyph = player_entity.glyph in
        let color = player_entity.color in
        Renderer.render_cell glyph color fc (x, y)
      else
        let glyph, color = Renderer.tile_glyph_and_color t in
        Renderer.render_cell glyph color fc (x, y))
    backend.map.map;

  None
