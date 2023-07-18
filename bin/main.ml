let finalize s = Io.save_to_file s "game.save"

let rec main_loop mode_state was_dead =
  let _ = was_dead in

  let dead_now =
    match mode_state with
    | State.Play s -> (
        match s.State.cm with State.CtrlM.Died _ -> true | _ -> false)
    | _ -> false
  in

  let mode_state' =
    match mode_state with State.Play s -> State.Play s | ms -> ms
  in

  let is_dead = dead_now in

  Raylib.begin_drawing ();
  Raylib.draw_text "Controls:" 20 20 10 Raylib.Color.raywhite;
  Raylib.end_drawing ();

  if mode_state' <> State.Exit then
    match Raylib.window_should_close () with
    (* Keep Playing *)
    | false -> main_loop mode_state' is_dead
    | true ->
        (* on exit *)
        (match mode_state' with State.Play s -> finalize s | _ -> ());
        main_loop State.Exit is_dead

let () =
  let title = "Rl2023 Ocaml Style" in
  let args = Rl2023.Cli.parse in
  Raylib.init_window args.width args.height title;
  Raylib.set_target_fps args.fps;
  Raylib.set_exit_key Raylib.Key.Escape;

  let state =
    let s =
      if Array.length Sys.argv > 1 then
        let s_prelim = Sys.argv.(1) in
        let opt_seed = if s_prelim = "?" then None else Some s_prelim in

        State.init_full opt_seed false
      else if Sys.file_exists "game.save" then Io.load_from_file "game.save"
      else State.init_full None false
    in

    State.Play s
  in

  main_loop state false

(* Cli.parse |> Game.setup "Rl2023 Ocaml Style" |> Menu.main_menu *)
