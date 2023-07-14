let setup (args : Rl2023.Cli.t) : unit =
  Raylib.init_window args.width args.height "Rl2023 Ocaml Style";
  Raylib.set_target_fps args.fps

let rec loop () =
  match Raylib.window_should_close () with
  | true -> Raylib.close_window ()
  | false ->
      let open Raylib in
      begin_drawing ();
      clear_background Color.raywhite;
      draw_text "Congrats! You created your first window!" 190 200 20
        Color.lightgray;
      end_drawing ();
      loop ()

let () = 
  Rl2023.Cli.parse |> setup |> loop

