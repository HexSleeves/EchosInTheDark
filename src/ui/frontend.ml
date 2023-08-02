(* Module *)
module B = Backend
module R = Renderer

let render (state : State.t) =
  match state.screen with
  | MainMenu s -> Mainmenu.render s
  | Play -> Play.render state

let handle_tick (s : State.t) =
  let state = match s.screen with _ -> s in
  state

let handle_event (s : State.t) =
  let state =
    match s.screen with Screen.Play -> Play.handle_event s | _ -> s
  in
  (state, false)

let run ()  =
  (Logs.info @@ fun m -> m "initializing frontend..."; print_newline ());

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
			{ State.screen; backend; player_pos = 10, 10; font }
    in

    (* Let's Roll *)
    let state = create_state Screen.Play in
    (Logs.info @@ fun m -> m "initialization done.");
    state, Mainloop.{ handle_event; handle_tick; render }
  in
  Mainloop.main init_fn
	[@@ocamlformat "disable"]
