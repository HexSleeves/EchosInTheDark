(* Module *)
module B = Backend
module R = Renderer
module S = State

let render (state : State.t) =
  match state.screen with
  | MainMenu s -> Mainmenu.render s
  | Play -> Play.render state

let handle_tick (s : State.t) =
  match s.screen with
  | MainMenu m ->
      let new_m, should_change = Mainmenu.handle_tick m in
      if should_change then S.to_play s else { s with screen = MainMenu new_m }
  | _ -> s

let handle_event (s : State.t) =
  match s.screen with
  | MainMenu m ->
      let new_m, should_quit = Mainmenu.handle_event m in
      ({ s with screen = MainMenu new_m }, should_quit)
  | Play ->
      let new_s = Play.handle_event s in
      (new_s, false)

let run () =
  ( Logs.info @@ fun m ->
    m "initializing frontend...";
    print_newline () );

  (* Initialize Game *)
  let init_fn font =
    (* Create State *)
    let create_state ?backend ?ui_options ?ui_view screen =
      let backend =
        match backend with
        | Some b -> b
        | None ->
            (* Used by different elements *)
            let random = Rng.get_state () in
            let seed = Rng.seed_int in
            B.make ~debug:true ~w:80 ~h:50 ~random ~seed
      in

      let _ = ui_options in
      let _ = ui_view in
      { State.screen; backend; player_pos = (10, 10); font }
    in

    (* Let's Roll *)
    let state = create_state (Screen.MainMenu Mainmenu.init) in
    (Logs.info @@ fun m -> m "initialization done.");
    (state, Mainloop.{ handle_event; handle_tick; render })
  in
  Mainloop.main init_fn
