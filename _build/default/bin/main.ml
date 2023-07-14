(* let setup () =
  Raylib.init_window 800 450 "raylib [core] example - basic window";
  Raylib.set_target_fps 60

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

let () = setup () |> loop

let () =
  for i = 0 to Array.length Sys.argv - 1 do
    Printf.printf "[%i] %s\n" i Sys.argv.(i)
  done *)

let setup w  () =
  Raylib.init_window 800 450 "raylib [core] example - basic window";
  Raylib.set_target_fps 60

let () = 
  Rl2023.Cli.parse |> setup