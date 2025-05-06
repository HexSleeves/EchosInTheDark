(** [render] draws the current game state, including the map and player.
    Rendering is synchronized with the updated state after movement, ensuring
    the player is always drawn at their current position. This function is
    structured for extensibility: to add animations, effects, or additional
    player states, extend the player rendering section as needed.

    Rendering pipeline: 1. Draw map tiles. 2. Draw player at their current
    position (from state). 3. (Extensible) Add effects, animations, or overlays
    as needed. *)

open Base
open Render
open Render_types
module T = Rl_types
module R = Render.Renderer
module Backend = Rl_core.Backend

let margin = Render_constants.margin
let log_height = Render_constants.log_height
let stats_bar_width_min = Render_constants.stats_bar_width_min
let stats_bar_width_frac = Render_constants.stats_bar_width_frac

let show_rect rect =
  Logs.info (fun m ->
      m "Rect: %s"
        (Printf.sprintf "x: %f, y: %f, width: %f, height: %f"
           (Raylib.Rectangle.x rect) (Raylib.Rectangle.y rect)
           (Raylib.Rectangle.width rect)
           (Raylib.Rectangle.height rect)))

let render (state : State.t) : State.t option =
  let backend = state.backend in

  let screen_w = Raylib.get_screen_width () in
  let screen_h = Raylib.get_screen_height () in
  let screen_wf = Float.of_int screen_w in
  let screen_hf = Float.of_int screen_h in
  let marginf = Float.of_int margin in

  (* Define UI panel dimensions and positions *)
  let top_bar_h = 60.0 in
  (* Adjust as needed *)
  let bottom_bar_h = 80.0 in
  (* Adjust as needed *)
  let right_sidebar_w = screen_wf *. 0.3 in
  (* 30% width *)

  let top_bar_rect =
    Raylib.Rectangle.create marginf marginf
      (screen_wf -. (2. *. marginf))
      top_bar_h
  in

  let main_view_rect =
    Raylib.Rectangle.create marginf (top_bar_h +. marginf)
      (screen_wf -. right_sidebar_w -. (2. *. marginf))
      (screen_hf -. top_bar_h -. bottom_bar_h -. (2. *. marginf))
  in

  let right_sidebar_rect =
    Raylib.Rectangle.create
      (screen_wf -. right_sidebar_w -. marginf)
      (top_bar_h +. marginf) right_sidebar_w
      (screen_hf -. top_bar_h -. bottom_bar_h -. (2. *. marginf))
  in

  let bottom_bar_rect =
    Raylib.Rectangle.create marginf
      (screen_hf -. bottom_bar_h -. marginf)
      (screen_wf -. (2. *. marginf))
      bottom_bar_h
  in

  (* Split right sidebar into minimap and message log areas *)
  let minimap_h = Raylib.Rectangle.height right_sidebar_rect *. 0.3 in
  let minimap_rect =
    Raylib.Rectangle.create
      (Raylib.Rectangle.x right_sidebar_rect)
      (Raylib.Rectangle.y right_sidebar_rect)
      (Raylib.Rectangle.width right_sidebar_rect)
      minimap_h
  in
  let message_log_rect =
    Raylib.Rectangle.create
      (Raylib.Rectangle.x right_sidebar_rect)
      (Raylib.Rectangle.y right_sidebar_rect +. minimap_h +. marginf)
      (Raylib.Rectangle.width right_sidebar_rect)
      (Raylib.Rectangle.height right_sidebar_rect -. minimap_h -. marginf)
  in

  let entities = Backend.get_entities backend in
  let player_id = Backend.get_player_id backend in
  let player_pos = Components.Position.get player_id in

  Option.iter player_pos ~f:(fun player_pos ->
      let chunk_manager = Backend.get_chunk_manager backend in
      let chunk_coords =
        Chunk_manager.world_to_chunk_coord player_pos.world_pos
      in

      let tile_render_size =
        Raylib.Vector2.create
          (Raylib.Rectangle.width main_view_rect
          /. Float.of_int Constants.chunk_w)
          (Raylib.Rectangle.height main_view_rect
          /. Float.of_int Constants.chunk_h)
      in

      Logs.debug (fun m ->
          m "Tile render size: %s"
            (Printf.sprintf "x: %f, y: %f"
               (Raylib.Vector2.x tile_render_size)
               (Raylib.Vector2.y tile_render_size)));

      let map_origin =
        Raylib.Vector2.create
          (Raylib.Rectangle.x main_view_rect)
          (Raylib.Rectangle.y main_view_rect)
      in
      let ctx = { state.render_ctx with tile_render_size } in

      (match Chunk_manager.get_loaded_chunk chunk_coords chunk_manager with
      | None -> ()
      | Some chunk ->
          Renderer.render_chunk chunk ~ctx ~backend ~map_origin ~entities);

      (* Draw a border around the main map view *)
      Raylib.draw_rectangle_lines_ex main_view_rect 2.0
        Render_constants.color_gold;

      (* Render other panels *)
      R.draw_top_bar ~rect:top_bar_rect ~ctx ~backend;
      R.draw_minimap ~rect:minimap_rect ~backend ~ctx;

      let messages = Ui_log.get_console_messages () in
      R.draw_message_log ~messages ~rect:message_log_rect;
      R.draw_bottom_bar ~rect:bottom_bar_rect ~ctx);

  if Backend.get_debug backend then R.render_fps_overlay ~ctx:state.render_ctx;

  None

let handle_mouse (state : State.t) =
  let open Raylib in
  if is_mouse_button_pressed MouseButton.Left then
    let tile_pos =
      Render_utils.screen_to_grid
        ~tile_render_size:state.render_ctx.tile_render_size
        (get_mouse_position ())
    in

    let position = Components.Position.make tile_pos in
    let backend =
      Backend.move_entity
        (Backend.get_player_id state.backend)
        position state.backend
    in
    { state with backend }
  else state

let handle_player_input (state : State.t) : State.t =
  let state = handle_mouse state in
  let action_opt = Input.get_current_action () in

  (* Local helper to convert render_mode to string *)
  let render_mode_to_string mode =
    match mode with
    | Render_constants.Ascii -> "ASCII"
    | Render_constants.Tiles -> "Tiles"
  in

  (* Handle UI actions *)
  let state =
    match action_opt with
    | Some Input.ToggleRender ->
        let current_mode = state.render_ctx.render_mode in
        let new_mode =
          match current_mode with
          | Render_constants.Ascii -> Render_constants.Tiles
          | Render_constants.Tiles -> Render_constants.Ascii
        in
        Ui_log.console "Toggled render mode to: %s"
          (render_mode_to_string new_mode);
        {
          state with
          render_ctx = { state.render_ctx with render_mode = new_mode };
        }
    | Some Input.ToggleEffects ->
        let backend =
          if Backend.get_config state.backend |> Backend.config_use_effects then
            Backend.disable_effects state.backend
          else Backend.enable_effects state.backend
        in

        let mode =
          if Backend.get_config backend |> Backend.config_use_effects then
            "enabled"
          else "disabled"
        in
        Ui_log.console "Effect handlers %s" mode;
        { state with backend }
    | Some Input.ToggleHybridMode ->
        let backend =
          if Backend.get_config state.backend |> Backend.config_use_hybrid then
            Backend.disable_effects state.backend
          else Backend.enable_hybrid state.backend
        in

        let mode =
          if Backend.get_config state.backend |> Backend.config_use_hybrid then
            "enabled"
          else "disabled"
        in
        Ui_log.console "Hybrid mode %s" mode;
        { state with backend }
    | Some Input.ToggleUnifiedMode ->
        let backend =
          if Backend.get_config state.backend |> Backend.config_use_unified then
            Backend.disable_effects state.backend
          else Backend.enable_unified state.backend
        in

        let mode =
          if Backend.get_config state.backend |> Backend.config_use_unified then
            "enabled"
          else "disabled"
        in
        Ui_log.console "Unified effect system %s" mode;
        { state with backend }
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
  let new_state =
    match Backend.get_mode backend with
    | T.CtrlMode.WaitInput -> handle_player_input state
    | T.CtrlMode.AI -> { state with backend = Backend.run_ai_step backend }
    | T.CtrlMode.Normal ->
        { state with backend = Backend.process_turns backend }
    | T.CtrlMode.Died _ ->
        {
          state with
          screen = GameOver;
          backend = Backend.set_mode T.CtrlMode.Normal backend;
        }
  in

  new_state
