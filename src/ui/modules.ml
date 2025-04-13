(* Main modules of game. They don't carry much state between them *)
module R = Renderer
module B = Backend
open Modules_d

let handle_tick (s : State.t) =
  let state =
    match s.screen with
    | MainMenu m ->
        let new_menu, should_quit, should_play = Mainmenu.handle_tick m in
        if should_play then { s with screen = Playing }
        else if should_quit then { s with quitting = true }
        else { s with screen = MainMenu new_menu }
    | _ -> s
  in
  state

let render (s : State.t) =
  match s.screen with
  | MapGen -> ()
  | MainMenu s -> Mainmenu.render s
  | Playing -> Play.render s

let run () : unit =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Debug);

  Printf.printf "Loading resources...";
  print_newline ();

  (* Initialize Game *)
  let init_fn font =
    (* Create State *)
    let create_state ?backend screen =
      let backend =
        match backend with
        | Some b -> b
        | None ->
            (* Used by different elements *)
            let random = Rng.get_state () in
            let seed = Rng.seed_int in
            B.make_default ~debug:true ~random ~seed
      in

      { font; backend; State.screen; player_pos = (10, 10); quitting = false }
    in

    (* Let's Roll *)
    let state = create_state (Modules_d.MainMenu Mainmenu.init) in
    (Logs.info @@ fun m -> m "initialization done.");
    (state, Mainloop.{ handle_tick; render })
  in
  Mainloop.main init_fn
