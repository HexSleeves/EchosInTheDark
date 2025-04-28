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

(* Console message buffer for backend logs *)
let max_console_messages = 10
let console_msgs : string list ref = ref []

let rec drop_console n l =
  if n <= 0 then l
  else match l with [] -> [] | _ :: tl -> drop_console (n - 1) tl

let add_console_message s =
  let msgs = !console_msgs @ [ s ] in
  let len_msgs = List.length msgs in
  console_msgs :=
    if len_msgs > max_console_messages then
      drop_console (len_msgs - max_console_messages) msgs
    else msgs

let get_console_messages () = !console_msgs
let console fmt = Printf.ksprintf add_console_message fmt
