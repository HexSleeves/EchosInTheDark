(* Copyright (c) 2016-2017 David Kaloper Meršinjak. All rights reserved.
   See LICENSE.md. *)

(*
 * Game of Life with some ZX spectrum kitsch.
 *)

type actions = [ `Game | `LoadGame ]

let file = ref ""
let mode : actions ref = ref `Game

let set v f =
  file := f;
  mode := v

let arglist = [ ("--load", Arg.String (set `LoadGame), "Load a save file") ]

let () =
  Arg.parse arglist (fun _ -> ()) "Usage";
  match !mode with
  | `Game -> Frontend.run ()
  | `LoadGame -> Frontend.run ~load:!file ()

(* Lwt_main.run @@ main () *)
