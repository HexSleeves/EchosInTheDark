(** [render] draws the current game state, including the map and player.
    Rendering is synchronized with the updated state after movement, ensuring
    the player is always drawn at their current position. This function is
    structured for extensibility: to add animations, effects, or additional
    player states, extend the player rendering section as needed.

    Rendering pipeline: 1. Draw map tiles. 2. Draw player at their current
    position (from state). 3. (Extensible) Add effects, animations, or overlays
    as needed. *)

open Base
module R = Renderer
module B = Rl_core.Backend
module T = Rl_core.Types
module M = Rl_core.Mode
module P = T.Pos
module A = Rl_core.Actor
module AM = Rl_core.Actor_manager
module Actions = Rl_core.Actions
module Turn_system = Rl_core.Turn_system

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
  let entities = B.get_entities backend in
  let entity_positions =
    Base.List.fold entities
      ~init:(Set.empty (module PosSet))
      ~f:(fun acc e -> Set.add acc e.pos)
  in

  (* Render map tiles, skipping those with an entity *)
  Array.iteri
    ~f:(fun i t ->
      let x = i % backend.map.width in
      let y = i / backend.map.width in
      if not (Set.mem entity_positions (x, y)) then
        let glyph, color = Grafx.tile_glyph_and_color t in
        Grafx.render_cell glyph color fc (x, y))
    backend.map.map;

  (* Render all entities as before *)
  List.iter entities ~f:(fun entity ->
      let glyph, color =
        match entity.kind with
        | Player -> ("@", Color.white)
        | Creature -> ("c", Color.red)
        | Item -> ("i", Color.yellow)
        | Other _ -> ("?", Color.gray)
      in
      Grafx.render_cell glyph color fc entity.pos);

  if backend.debug then render_fps fc;
  None

let handle_player_input (state : State.t) : State.t =
  let open Raylib in
  let dir_opt =
    if is_key_pressed Key.W || is_key_pressed Key.Up then Some P.North
    else if is_key_pressed Key.S || is_key_pressed Key.Down then Some P.South
    else if is_key_pressed Key.A || is_key_pressed Key.Left then Some P.West
    else if is_key_pressed Key.D || is_key_pressed Key.Right then Some P.East
    else None
  in
  match dir_opt with
  | Some dir ->
      let am = state.backend.actor_manager in
      let entity = B.get_player state.backend in
      let action = Actions.make_move_action dir entity in

      AM.update am entity.id (fun actor -> A.queue_action actor action);

      {
        state with
        backend =
          { state.backend with mode = M.CtrlMode.Normal; actor_manager = am };
      }
  | None -> state

let handle_tick (state : State.t) : State.t =
  let backend = state.backend in

  match backend.mode with
  | M.CtrlMode.Normal ->
      let new_backend = Turn_system.process_turns backend in
      { state with backend = new_backend }
  | M.CtrlMode.WaitInput -> handle_player_input state
  | M.CtrlMode.Died _ ->
      (Logs.info @@ fun m -> m "Player died");
      state
