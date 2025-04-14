(** [render] draws the current game state, including the map and player.
    Rendering is synchronized with the updated state after movement, ensuring
    the player is always drawn at their current position. This function is
    structured for extensibility: to add animations, effects, or additional
    player states, extend the player rendering section as needed.

    Rendering pipeline: 1. Draw map tiles. 2. Draw player at their current
    position (from state). 3. (Extensible) Add effects, animations, or overlays
    as needed. *)

open Base

let render_fps (fc : Renderer.font_config) : unit =
  let open Raylib in
  (* Draw FPS counter *)
  let fps = get_fps () in
  let fps_text = Int.to_string fps in

  (* Measure the text width using the correct font size *)
  let text_width = measure_text fps_text fc.font_size in
  let padding = 4 in

  (* Add some padding around the text *)
  let box_height = Float.of_int (fc.font_size + (padding * 2)) in
  let box_width = Float.of_int (text_width + (padding * 2)) in

  (* Position the box at the top-left corner (adjust as needed) *)
  let padding = Float.of_int padding in
  let box_x = Float.of_int (get_screen_width ()) -. box_width -. padding in
  let box_y = Float.of_int (get_screen_height ()) -. box_height -. padding in

  (* Create the rectangle *)
  let box = Rectangle.create box_x box_y box_width box_height in

  (* Draw the semi-transparent black background box *)
  (* Using fade makes it less intrusive *)
  draw_rectangle_rec box (Raylib.fade Color.gray 0.75);

  (* Calculate text position inside the box with padding *)
  let text_x = Int.of_float (box_x +. padding) in
  let text_y = Int.of_float (box_y +. padding) in

  (* Draw the FPS text using draw_text for precise positioning *)
  draw_text fps_text text_x text_y fc.font_size Color.white

let render (state : State.t) : State.t option =
  let open Raylib in
  let backend = state.backend in
  let fc = state.font_config in

  (* --- 1. Render map tiles --- *)
  Array.iteri
    ~f:(fun i t ->
      let x = i % backend.map.width in
      let y = i / backend.map.width in
      let glyph, color = Renderer.tile_glyph_and_color t in
      Renderer.render_cell glyph color fc (x, y))
    backend.map.map;

  (* --- 2. Render all entities --- *)
  let entities = Backend.get_entities backend in
  Base.List.iter entities ~f:(fun entity ->
      let glyph, color =
        match entity.kind with
        | Player -> ("@", Color.white)
        | Creature -> ("c", Color.red)
        | Item -> ("i", Color.yellow)
        | Other _ -> ("?", Color.gray)
      in
      Renderer.render_cell glyph color fc entity.pos);

  (* Draw FPS counter *)
  if backend.debug then render_fps fc;

  (* --- 3. (Extensible) Add effects, animations, overlays here --- *)
  (* Example: To add player animation, replace glyph/color based on state *)
  None
