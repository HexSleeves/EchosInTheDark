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
