(* Module *)
module B = Backend
module R = Renderer

let render (state : State.t) =
  match state.screen with
  | MainMenu -> ()
  | MapGen _data -> ()
  (* | Play -> Play.render state *)
  | Play -> ()
;;

let handle_tick (s : State.t) (time : int) =
  let state =
    match s.screen with
    | _ -> s
  in
  Lwt.return state
;;

let handle_event (s : State.t) (e : Event.t) =
  let state =
    match s.screen with
    | Screen.MapGen (Some { state = `Done; _ }) -> s
    | Screen.Play -> s
    | _ -> s
  in
  Lwt.return state, false
;;

let run () : unit Lwt.t =
  (Logs.info @@ fun m -> m "initializing frontend..."; print_newline ());

  (* Initialize Game *)
  let init_fn win =
    (* Create State *)
    let create_state ?backend ?ui_options ?ui_view screen =
      let backend =
        match backend with
        | Some b -> b
        | None ->
          (* Used by different elements *)
          Random.self_init ();
          let random = Utils.Random.get_state () in
          let seed = Random.State.int random 0x7FFF in
          B.default ~w:300 ~h:300 ~random ~seed
      in
      let _ = ui_options in
      let _ = ui_view in
      let _ = win in
      Lwt.return { State.screen; backend; player_pos = 0, 0 }
    in

    (* Let's Roll *)
    let state = create_state Screen.Play in
    (Logs.info @@ fun m -> m "initialization done.");
    state, Mainloop.{ handle_event; handle_tick; render }
  in
  Mainloop.main init_fn
	[@@ocamlformat "disable"]
