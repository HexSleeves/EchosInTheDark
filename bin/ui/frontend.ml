open Containers
module B = Backend

let render (s : State.t) = Screen.render s.term s.screen

let handle_tick (s : State.t) =
  let state = match s.screen with _ -> s in
  Lwt.return state

let handle_event (s : State.t) e =
  let state =
    match s.screen with
    | Screen.MapGen (Some { state = `Done; _ }) ->
        (* match event with
           | Key { down = true; _ } ->
               (* Printf.printf "Mapview\n"; *)
               { s with screen = Screen.MapView }
           | _ -> s) *)
        s
    | Screen.Play ->
        (* let ui, backend_msgs = Main_ui.handle_event s s.ui event in *)
        (* let backend = Backend.Action.run s.backend backend_msgs in *)
        (* if s.ui =!= ui then s.ui <- ui; *)
        (* if s.backend =!= backend then s.backend <- backend; *)
        s
    | _ -> s
  in
  (state, false)

let run () : unit Lwt.t =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Info);

  ( Logs.info @@ fun m ->
    m "initializing frontend...";
    print_newline () );

  (* Initialize Game *)
  let init_fn win =
    (* Create State *)
    let create_state ?backend ?ui_options ?ui_view screen =
      let open Notty_lwt in
      let term = Term.create ~dispose:true () in
      let w, h = Term.size term in

      let backend =
        match backend with
        | Some b -> b
        | None ->
            (* Used by different elements *)
            Random.self_init ();
            let random = Random.get_state () in
            let seed = Random.int 0x7FFF random in
            B.default w h ~random ~seed
      in

      let _ = ui_options in
      let _ = ui_view in
      let _ = win in

      { State.screen; backend; term }
    in

    (* Let's Roll *)
    let state = create_state Screen.Play in
    (Logs.info @@ fun m -> m "initialization done.");
    (state, Mainloop.{ handle_event; handle_tick; render })
  in

  Mainloop.main init_fn
