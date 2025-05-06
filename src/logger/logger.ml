(* Core_log: Logging functions for the core subsystem.
   All logging in the core subsystem should use this module. *)

(* Per-file/module logger *)
let make_logger name =
  let src = Logs.Src.create name ~doc:(name ^ " module logs") in
  let module M = (val Logs.src_log src : Logs.LOG) in
  (module M : Logs.LOG)

let err = Logs.err
let warn = Logs.warn
let info = Logs.info
let debug = Logs.debug
