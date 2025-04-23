(* Copyright (c) 2025 Jacob LeCoq (Yendor). All rights reserved. *)

let () =
  (* CLI argument refs *)
  let debug = ref false in
  let seed = ref None in
  let log_level = ref "info" in

  let speclist =
    [
      ("--debug", Arg.Set debug, "Enable debug mode");
      ( "--seed",
        Arg.String (fun s -> seed := Some (int_of_string s)),
        "Random seed (int)" );
      ( "--log-level",
        Arg.Set_string log_level,
        "Log level (app|info|debug|warn|error)" );
    ]
  in
  let usage = "Rougelike Tutorial 2025 [options]" in
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

  (* 1. Create window and font config *)
  let font_config = Rl_ui.Renderer.create () in

  (* 2. Compute map area (must match your play.ml layout) *)
  let screen_w = Raylib.get_screen_width () in
  let screen_h = Raylib.get_screen_height () in

  let stats_bar_w =
    max Rl_ui.Renderer.Ui_constants.stats_bar_width_min
      (screen_w |> float_of_int
      |> ( *. ) Rl_ui.Renderer.Ui_constants.stats_bar_width_frac
      |> int_of_float)
  in
  let log_h = Rl_ui.Renderer.Ui_constants.log_height in

  let map_w = screen_w - stats_bar_w in
  let map_h = screen_h - log_h in

  (* 3. Compute font size and map size *)
  let map_width_tiles = map_w / font_config.font_size in
  let map_height_tiles = map_h / font_config.font_size in

  let config =
    {
      Rl_ui.Modules.font_config;
      seed = !seed;
      debug = !debug;
      width = map_width_tiles;
      height = map_height_tiles;
      backend = None;
    }
  in

  Logs.info (fun m -> m "Starting main");
  Rl_ui.Modules.run_with_config config
