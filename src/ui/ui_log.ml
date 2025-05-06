(* Ui_log: Logging functions for the UI subsystem.
   All logging in the UI subsystem should use this module. *)

let src = Logs.Src.create "ui" ~doc:"UI subsystem logs"

module Log = (val Logs.src_log src : Logs.LOG)
(* Use top-level Core_log for shared console buffer *)
(* Assuming dune links the core_log library, Core_log is available globally *)

let err = Log.err
let warn = Log.warn
let info = Log.info
let debug = Log.debug

(* Redirect UI console logging to shared core log buffer *)
let console = Core_log.console
let get_console_messages = Core_log.get_console_messages
