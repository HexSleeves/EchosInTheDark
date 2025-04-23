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
module Ui_constants = R.Ui_constants

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

  let screen_w = Raylib.get_screen_width () in
  let screen_h = Raylib.get_screen_height () in
  let stats_bar_w =
    max Ui_constants.stats_bar_width_min
      (Int.of_float
         (Float.of_int screen_w *. Ui_constants.stats_bar_width_frac))
  in
  let log_h = Ui_constants.log_height in
  let map_w = screen_w - stats_bar_w in
  let map_h = screen_h - log_h in

  let map_rect =
    Raylib.Rectangle.create 0. 0. (Float.of_int map_w) (Float.of_int map_h)
  in
  let stats_rect =
    Raylib.Rectangle.create (Float.of_int map_w) 0. (Float.of_int stats_bar_w)
      (Float.of_int screen_h)
  in
  let log_rect =
    Raylib.Rectangle.create 0. (Float.of_int map_h) (Float.of_int map_w)
      (Float.of_int log_h)
  in

  let entities = Backend.get_entities backend in
  let entity_positions = R.occupied_positions entities in
  let current_map = Backend.get_current_map backend in
  let map_origin =
    Raylib.Vector2.create
      (Float.of_int (Int.of_float (Raylib.Rectangle.x map_rect)))
      (Float.of_int (Int.of_float (Raylib.Rectangle.y map_rect)))
  in
  R.render_map_tiles ~tiles:current_map.map ~width:current_map.width
    ~skip_positions:entity_positions ~font_config:fc ~origin:map_origin;
  R.render_entities ~entities ~font_config:fc ~origin:map_origin;

  (* Render stats bar *)
  let player = Backend.get_player_entity backend in
  R.draw_stats_bar_vertical ~player ~rect:stats_rect;

  (* Render message log (stub: use dummy messages for now) *)
  let messages =
    [ "Welcome to the dungeon!"; "You see a rat."; "You attack the rat." ]
  in
  R.draw_message_log ~messages ~rect:log_rect;

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
