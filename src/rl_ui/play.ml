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

let render (state : State.t) : State.t option =
  let backend = state.backend in
  let fc = state.font_config in

  let entities = Backend.get_entities backend in
  let entity_positions = R.occupied_positions entities in
  let current_map = Backend.get_current_map backend in

  R.render_map_tiles ~tiles:current_map.map ~width:current_map.width
    ~skip_positions:entity_positions ~font_config:fc;
  R.render_entities ~entities ~font_config:fc;

  if Rl_core.State.get_debug backend then R.draw_fps_overlay fc;
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
