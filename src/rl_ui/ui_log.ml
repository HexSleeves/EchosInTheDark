(* Ui_log: Logging functions for the UI subsystem.
   All logging in the UI subsystem should use this module. *)

let src = Logs.Src.create "ui" ~doc:"UI subsystem logs"

module Log = (val Logs.src_log src : Logs.LOG)

let err = Log.err
let warn = Log.warn
let info = Log.info
let debug = Log.debug
