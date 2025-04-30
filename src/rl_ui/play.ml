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
module T = Types
module Backend = Rl_core.Backend

let margin = Constants.margin
let log_height = Constants.log_height
let stats_bar_width_min = Constants.stats_bar_width_min
let stats_bar_width_frac = Constants.stats_bar_width_frac

module PosSet = struct
  module T = struct
    type t = int * int [@@deriving compare, sexp]
  end

  include T
  include Comparator.Make (T)
end

let render (state : State.t) : State.t option =
  let backend = state.backend in
  let ctx = state.render_ctx in

  let screen_w = Raylib.get_screen_width () in
  let screen_h = Raylib.get_screen_height () in

  let stats_bar_w =
    max stats_bar_width_min
      (Int.of_float (Float.of_int screen_w *. stats_bar_width_frac))
  in

  let log_h = log_height in
  let map_w = screen_w - stats_bar_w - (2 * margin) in
  let map_h = screen_h - log_h - (2 * margin) in

  let map_rect =
    Raylib.Rectangle.create (Float.of_int margin) (Float.of_int margin)
      (Float.of_int map_w) (Float.of_int map_h)
  in
  let stats_rect =
    Raylib.Rectangle.create
      (Float.of_int (map_w + (2 * margin)))
      0. (Float.of_int stats_bar_w) (Float.of_int screen_h)
  in
  let log_rect =
    Raylib.Rectangle.create (Float.of_int margin)
      (Float.of_int (map_h + margin))
      (Float.of_int map_w) (Float.of_int log_h)
  in

  let entities = Backend.get_entities backend in
  (* TODO: Integrate chunk-based rendering here. The old get_current_map is gone. *)

  let player_id = Backend.get_player_id backend in
  let player_pos = Components.Position.get_exn player_id in
  let chunk_manager = Backend.get_chunk_manager backend in
  let chunk_coords = Chunk_manager.world_to_chunk_coord player_pos in

  ignore
    (match Chunk_manager.get_loaded_chunk chunk_manager chunk_coords with
    | None -> ()
    | Some chunk ->
        let map_origin =
          Raylib.Vector2.create
            (Raylib.Rectangle.x map_rect)
            (Raylib.Rectangle.y map_rect)
        in
        let entity_positions =
          Render_utils.occupied_positions (Backend.get_entities backend)
        in

        Renderer.render_map_tiles
          ~tiles:(Array.concat (Array.to_list chunk.tiles))
          ~width:Chunk_manager.chunk_width ~skip_positions:entity_positions
          ~origin:map_origin ~ctx;

        Renderer.render_entities ~entities ~chunk_coords ~origin:map_origin ~ctx);

  (* Render stats bar *)
  R.draw_stats_bar_vertical
    ~player_id:(Backend.get_player_id backend)
    ~rect:stats_rect ~ctx;

  (* Render message log from UI console buffer *)
  (* let messages = Ui_log.get_console_messages () in
  R.draw_message_log ~messages ~rect:log_rect; *)
  if Backend.get_debug backend then R.render_fps_overlay ctx.font_config;
  None

let handle_mouse (state : State.t) =
  let open Raylib in
  if is_mouse_button_pressed MouseButton.Left then
    let mouse_pos = get_mouse_position () in
    let tile_pos = Render_utils.screen_to_grid mouse_pos in
    let player_id = Backend.get_player_id state.backend in
    let b = Backend.move_entity player_id tile_pos state.backend in
    { state with backend = b }
  else state

let handle_player_input (state : State.t) : State.t =
  let state = handle_mouse state in
  let action_opt = Input.get_current_action () in

  (* Handle UI actions *)
  let state =
    match action_opt with
    | Some Input.ToggleRender ->
        let () = Constants.toggle_render_mode () in
        let new_mode = !Constants.render_mode_ref in
        Ui_log.console "Toggled render mode to: %s"
          (Constants.render_mode_to_string new_mode);
        {
          state with
          render_ctx = { state.render_ctx with render_mode = new_mode };
        }
    | _ -> state
  in

  match action_opt with
  | Some (Input.Backend action) ->
      let backend =
        Backend.queue_actor_action state.backend
          (Backend.get_player_id state.backend)
          action
      in
      { state with backend = Backend.set_mode T.CtrlMode.AI backend }
  | _ -> state

let handle_tick (state : State.t) : State.t =
  let open Rl_core in
  let backend = state.backend in
  match Backend.get_mode backend with
  | T.CtrlMode.WaitInput -> handle_player_input state
  | T.CtrlMode.AI -> { state with backend = Backend.run_ai_step backend }
  | T.CtrlMode.Normal -> { state with backend = Backend.process_turns backend }
  | T.CtrlMode.Died _ ->
      {
        state with
        screen = GameOver;
        backend = Backend.set_mode T.CtrlMode.Normal backend;
      }
