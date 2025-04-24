(* Core_log: Logging functions for the core subsystem.
   All logging in the core subsystem should use this module. *)

let src = Logs.Src.create "core" ~doc:"Core subsystem logs"

module Log = (val Logs.src_log src : Logs.LOG)

let err = Log.err
let warn = Log.warn
let info = Log.info
let debug = Log.debug

(* Per-file/module logger *)
let make_logger name =
  let src = Logs.Src.create name ~doc:(name ^ " module logs") in
  let module M = (val Logs.src_log src : Logs.LOG) in
  (module M : Logs.LOG)
