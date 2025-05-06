(* Copyright (c) 2025 Jacob LeCoq (Yendor). All rights reserved. *)
open Render

let margin = Render_constants.margin
let log_height = Render_constants.log_height
let stats_bar_width_min = Render_constants.stats_bar_width_min
let stats_bar_width_frac = Render_constants.stats_bar_width_frac

let () =
  (* CLI argument refs *)
  let debug = ref false in
  let seed = ref None in
  let log_level = ref "info" in
  let enable_profiling = ref false in

  let speclist =
    [
      ("--debug", Arg.Set debug, "Enable debug mode");
      ( "--seed",
        Arg.String (fun s -> seed := Some (int_of_string s)),
        "Random seed (int)" );
      ( "--log-level",
        Arg.Set_string log_level,
        "Log level (app|info|debug|warn|error)" );
      ("--profile", Arg.Set enable_profiling, "Enable performance profiling");
    ]
  in
  let usage = "Echoes in the Dark [options]" in
  Arg.parse speclist (fun _ -> ()) usage;

  let level =
    match String.lowercase_ascii !log_level with
    | "app" -> Logs.App
    | "debug" -> Logs.Debug
    | "warn" -> Logs.Warning
    | "error" -> Logs.Error
    | _ -> Logs.Info
  in

  Logger.setup_logger level;

  (* Initialize profiling if enabled *)
  if !enable_profiling then
    Logs.info (fun m -> m "Performance profiling enabled")
    (* It will be run at the appropriate time in the game loop *);

  (* 1. Create window and font config *)
  let render_ctx = Renderer.create_render_context () in

  (* 2. Compute map area (must match your play.ml layout) *)
  let screen_w = Raylib.get_screen_width () in
  let screen_h = Raylib.get_screen_height () in

  let log_h = log_height in
  let stats_bar_w =
    max stats_bar_width_min
      (screen_w |> float_of_int |> ( *. ) stats_bar_width_frac |> int_of_float)
  in

  let map_w = screen_w - stats_bar_w - (2 * margin) in
  let map_h = screen_h - log_h - (2 * margin) in

  let map_width_tiles = (map_w / render_ctx.font_config.font_size) + 1 in
  let map_height_tiles = map_h / render_ctx.font_config.font_size in

  let config : Ui.Modules.init_config =
    {
      seed = !seed;
      debug = !debug;
      width = map_width_tiles;
      height = map_height_tiles;
      backend = None;
      enable_profiling = !enable_profiling;
    }
  in

  Logs.info (fun m -> m "Starting main loop");
  Ui.Modules.run_with_config render_ctx config
