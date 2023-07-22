(* Copyright (c) 2023 Jacob LeCoq (Yendor). All rights reserved. *)

open Arg

type actions = [ `Game ]

let file = ref ""
let verbose = ref false
let mode : actions ref = ref `Game

let set v f =
  file := f;
  mode := v

let arglist = [ ("-debug", Arg.Set verbose, "Output debug information") ]

let () =
  parse arglist (fun _ -> ()) "rl2023 [-verbose]";
  match !mode with `Game -> Frontend.run ()
