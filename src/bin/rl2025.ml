(* Copyright (c) 2025 Jacob LeCoq (Yendor). All rights reserved. *)

let () =
  (* CLI argument refs *)
  let debug = ref false in
  let seed = ref None in
  let width = ref 80 in
  let height = ref 50 in
  let log_level = ref "info" in

  let speclist =
    [
      ("--debug", Arg.Set debug, "Enable debug mode");
      ( "--seed",
        Arg.String (fun s -> seed := Some (int_of_string s)),
        "Random seed (int)" );
      ("--width", Arg.Int (fun w -> width := w), "Map width");
      ("--height", Arg.Int (fun h -> height := h), "Map height");
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

  let font_config = Rl_ui.Renderer.create () in
  let config =
    {
      Rl_ui.Modules.font_config;
      seed = !seed;
      debug = !debug;
      width = !width;
      height = !height;
      backend = None;
    }
  in

  Logs.info (fun m -> m "Starting main");
  Rl_ui.Modules.run_with_config config
