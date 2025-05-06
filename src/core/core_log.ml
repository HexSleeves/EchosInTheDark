(* Core_log: Logging functions for the core subsystem.
   All logging in the core subsystem should use this module. *)

module Log = (val Logger.make_logger "core")

let err = Log.err
let warn = Log.warn
let info = Log.info
let debug = Log.debug
