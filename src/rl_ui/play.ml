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
open State

module PosSet = struct
  module T = struct
    type t = int * int [@@deriving compare, sexp]
  end

  include T
  include Comparator.Make (T)
end

let initial_delay = 0.3
let repeat_delay = 0.08

let is_movement_key key =
  match key with
  | Raylib.Key.W | Raylib.Key.A | Raylib.Key.S | Raylib.Key.D | Raylib.Key.Up
  | Raylib.Key.Down | Raylib.Key.Left | Raylib.Key.Right ->
      true
  | _ -> false

let get_held_movement_key () =
  let open Raylib in
  let keys =
    [ Key.W; Key.A; Key.S; Key.D; Key.Up; Key.Down; Key.Left; Key.Right ]
  in
  List.find_map keys ~f:(fun k -> if is_key_down k then Some k else None)

let render (state : t) : t option =
  let backend = state.backend in
  let ctx = state.render_ctx in

  let screen_w = Raylib.get_screen_width () in
  let screen_h = Raylib.get_screen_height () in
  let stats_bar_w =
    max Constants.stats_bar_width_min
      (Int.of_float (Float.of_int screen_w *. Constants.stats_bar_width_frac))
  in
  let log_h = Constants.log_height in
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
  let entity_positions = Render_utils.occupied_positions entities in
  let current_map = Backend.get_current_map backend in
  let map_origin =
    Raylib.Vector2.create
      (Float.of_int (Int.of_float (Raylib.Rectangle.x map_rect)))
      (Float.of_int (Int.of_float (Raylib.Rectangle.y map_rect)))
  in

  (* Debug: Print tile at player position in UI and backend *)
  R.render_map_tiles ~tiles:current_map.map ~width:current_map.width
    ~skip_positions:entity_positions ~origin:map_origin ~ctx;
  R.render_entities ~entities ~origin:map_origin ~ctx;

  (* Render stats bar *)
  let player = Backend.get_player_entity backend in
  R.draw_stats_bar_vertical ~player ~rect:stats_rect;

  (* Render message log (stub: use dummy messages for now) *)
  let messages =
    [ "Welcome to the dungeon!"; "You see a rat."; "You attack the rat." ]
  in
  R.draw_message_log ~messages ~rect:log_rect;

  if Rl_core.State.get_debug backend then R.render_fps_overlay ctx.font_config;
  None

let handle_mouse (state : t) =
  let open Raylib in
  if is_mouse_button_pressed MouseButton.Left then
    let mouse_pos = get_mouse_position () in
    let tile_pos = Render_utils.screen_to_grid mouse_pos in
    let player_id = Backend.get_player_id state.backend in
    let b = Backend.move_entity player_id tile_pos state.backend in
    { state with backend = b }
  else state

let handle_player_input (state : t) : t =
  let state = handle_mouse state in
  let now = Raylib.get_time () in
  let ic = state.input_ctx in
  let held_key_opt = get_held_movement_key () in
  let input_ctx =
    match (held_key_opt, ic.held_key) with
    | Some k, None when is_movement_key k ->
        {
          State.Input_context.held_key = Some k;
          State.Input_context.held_since = Some now;
          State.Input_context.last_repeat = None;
        }
    | Some k, Some k' when (not (phys_equal k k')) && is_movement_key k ->
        {
          State.Input_context.held_key = Some k;
          State.Input_context.held_since = Some now;
          State.Input_context.last_repeat = None;
        }
    | None, _ ->
        {
          State.Input_context.held_key = None;
          State.Input_context.held_since = None;
          State.Input_context.last_repeat = None;
        }
    | _, _ -> ic
  in
  let state = { state with input_ctx } in
  (* Handle render mode toggle key (T) *)
  let state =
    if Rl_core.Input.is_render_toggle_pressed () then (
      let () = Constants.toggle_render_mode () in
      let new_mode = !Constants.render_mode_ref in
      Ui_log.info (fun m ->
          m "Toggled render mode to: %s"
            (Constants.render_mode_to_string new_mode));
      let new_ctx = { state.render_ctx with render_mode = new_mode } in
      { state with render_ctx = new_ctx })
    else state
  in
  (* Only process action if enough time has passed for repeat *)
  match input_ctx.held_key with
  | Some k when is_movement_key k ->
      let can_repeat =
        match (input_ctx.held_since, input_ctx.last_repeat) with
        | Some _, None -> true (* First press: act immediately *)
        | Some since, Some last ->
            let delay =
              if Float.compare last since = 0 then initial_delay
              else repeat_delay
            in
            Float.compare (now -. last) delay >= 0
        | _ -> false
      in
      if can_repeat then
        match I.of_key k with
        | Some action ->
            Ui_log.info (fun m ->
                m "Player action (repeat): %s" (T.Action.to_string action));
            let entity = Backend.get_player_entity state.backend in
            let backend =
              Backend.queue_actor_action state.backend
                (T.Entity.get_base entity).id action
            in
            {
              state with
              backend = Backend.set_mode T.CtrlMode.Normal backend;
              input_ctx =
                { input_ctx with State.Input_context.last_repeat = Some now };
            }
        | None -> state
      else state
  | _ -> (
      match I.action_from_keys () with
      | Some action ->
          Ui_log.info (fun m ->
              m "Player action: %s" (T.Action.to_string action));
          let entity = Backend.get_player_entity state.backend in
          let backend =
            Backend.queue_actor_action state.backend
              (T.Entity.get_base entity).id action
          in
          { state with backend = Backend.set_mode T.CtrlMode.Normal backend }
      | None -> state)

let handle_tick (state : t) : t =
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
        backend = Backend.set_mode T.CtrlMode.Normal backend;
      }
