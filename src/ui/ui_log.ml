(* Ui_log: Logging functions for the UI subsystem.
   All logging in the UI subsystem should use this module. *)

module Log = (val Logger.make_logger "ui")

let err = Log.err
let warn = Log.warn
let info = Log.info
let debug = Log.debug
