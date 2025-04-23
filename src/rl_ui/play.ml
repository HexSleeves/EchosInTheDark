(** [render] draws the current game state, including the map and player.
    Rendering is synchronized with the updated state after movement, ensuring
    the player is always drawn at their current position. This function is
    structured for extensibility: to add animations, effects, or additional
    player states, extend the player rendering section as needed.

    Rendering pipeline: 1. Draw map tiles. 2. Draw player at their current
    position (from state). 3. (Extensible) Add effects, animations, or overlays
    as needed. *)

open Base
open Renderer
module R = Renderer
module T = Rl_core.Types
module I = Rl_core.Input
module Backend = Rl_core.Backend

module PosSet = struct
  module T = struct
    type t = int * int [@@deriving compare, sexp]
  end

  include T
  include Comparator.Make (T)
end

let render_fps (fc : R.font_config) : unit =
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

  (* Collect all entity positions into a set *)
  let entities = Backend.get_entities backend in
  let entity_positions =
    Base.List.fold entities
      ~init:(Set.empty (module PosSet))
      ~f:(fun acc e ->
        let e = T.Entity.get_base e in
        Set.add acc (e.pos.x, e.pos.y))
  in

  (* Render map tiles, skipping those with an entity *)
  let current_map = Backend.get_current_map backend in
  Array.iteri
    ~f:(fun i t ->
      let x = i % current_map.width in
      let y = i / current_map.width in
      if not (Set.mem entity_positions (x, y)) then
        let glyph, color = tile_glyph_and_color t in
        render_cell glyph color fc (T.Loc.make x y))
    current_map.map;

  (* Render all entities as before *)
  List.iter entities ~f:(fun entity ->
      let color =
        match entity with
        | T.Entity.Player _ -> Color.white
        | T.Entity.Creature _ -> Color.red
        | T.Entity.Item _ -> Color.yellow
        | T.Entity.Corpse _ -> Color.gray
      in
      let e = T.Entity.get_base entity in
      render_cell e.glyph color fc e.pos);

  if Rl_core.State.get_debug backend then render_fps fc;
  None

let handle_mouse (state : State.t) =
  let open Raylib in
  if is_mouse_button_pressed MouseButton.Left then
    let mouse_pos = get_mouse_position () in
    let tile_pos = R.screen_to_grid mouse_pos in
    let player_id = Backend.get_player_id state.backend in
    let b = Backend.move_entity state.backend player_id tile_pos in
    { state with backend = b }
  else state

let handle_player_input (state : State.t) : State.t =
  let state = handle_mouse state in

  match I.action_from_keys () with
  | Some action ->
      Ui_log.info (fun m -> m "Player action: %s" (T.Action.to_string action));
      let entity = Backend.get_player_entity state.backend in
      let backend =
        Backend.queue_actor_action state.backend (T.Entity.get_base entity).id
          action
      in
      { state with backend = Backend.set_mode backend T.CtrlMode.Normal }
  | None -> state

let handle_tick (state : State.t) : State.t =
  let open Rl_core in
  let backend = state.backend in

  match Backend.get_mode backend with
  | T.CtrlMode.WaitInput -> handle_player_input state
  | T.CtrlMode.Normal ->
      { state with backend = Turn_system.process_turns backend }
  | T.CtrlMode.Died _ ->
      {
        state with
        screen = GameOver;
        backend = Backend.set_mode backend T.CtrlMode.Normal;
      }
