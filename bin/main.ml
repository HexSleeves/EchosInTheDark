(* type object_t = { x: int ; y: int  } *)

let setup (args : Rl2023.Cli.t) : unit =
  Raylib.init_window args.width args.height "Rl2023 Ocaml Style";
  Raylib.set_target_fps args.fps

(* let new_game () =
  let player = { x = 0 ; y = 0 } 
;; *)

let () = 
  Rl2023.Cli.parse |> setup |> Menu.main_menu