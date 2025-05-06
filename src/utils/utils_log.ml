(* Utils_log: Logging functions for the utils subsystem.
   All logging in the utils subsystem should use this module. *)

let src = Logs.Src.create "utils" ~doc:"Utils subsystem logs"

module Log = (val Logs.src_log src : Logs.LOG)

let err = Log.err
let warn = Log.warn
let info = Log.info
let debug = Log.debug
