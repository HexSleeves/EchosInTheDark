(* Copyright (c) 2025 Jacob LeCoq (Yendor). All rights reserved. *)

open Logs
open Rl2025

let () =
  Clap.description "Rougelike Tutorial 2025";
  (* [flag_enum] is a generalization of [flag] for enums with more than 2 possible values. *)
  let level =
    Clap.flag_enum ~description:"Logging level"
      [
        ([ "app" ], [ 'a' ], App);
        ([ "info" ], [ 'i' ], Info);
        ([ "debug" ], [ 'd' ], Debug);
        ([ "warn" ], [ 'w' ], Warning);
        ([ "error" ], [ 'e' ], Error);
      ]
      Info
  in
  Clap.close ();
  Log.configure ~level;
  (* Blast Off *)
  let () = Log.info "Starting main" in
  Modules.run ()
