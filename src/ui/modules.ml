open Modules_d

(* Main modules of game. They don't carry much state between them *)
module R = Renderer
module B = Backend

let option_to_screen (s : State.t) (update : 'a option)
    (scrn_constructor : 'a -> Modules_d.screen) : State.t option =
  match update with
  | Some new_screen_state ->
      Some { s with screen = scrn_constructor new_screen_state }
  | None -> None

let handle_tick (s : State.t) =
  let state =
    match s.screen with
    | MainMenu m -> (
        let new_mainmenu, result = Mainmenu.handle_tick m in
        match result with
        | Some Play -> { s with screen = MapGen Mapgen.init }
        | Some Quit ->
            { s with quitting = true; screen = MainMenu new_mainmenu }
        | None -> { s with screen = MainMenu new_mainmenu })
    | MapGen m -> (
        let new_mapgen = Mapgen.handle_tick m in
        match new_mapgen.action with
        | Some `Continue -> { s with screen = Playing }
        | Some `Back -> { s with screen = MainMenu Mainmenu.init }
        | None -> { s with screen = MapGen new_mapgen })
    | _ -> s
  in
  state

let render (s : State.t) : State.t option =
  match s.screen with
  | MapGen m ->
      option_to_screen s (Mapgen.render m) (fun x -> Modules_d.MapGen x)
  | MainMenu m ->
      option_to_screen s (Mainmenu.render m) (fun x -> Modules_d.MainMenu x)
  | Playing -> option_to_screen s (Play.render s) (fun _ -> Modules_d.Playing)

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
    let state = create_state (MainMenu Mainmenu.init) in
    (Logs.info @@ fun m -> m "initialization done.");
    (state, Mainloop.{ handle_tick; render })
  in
  Mainloop.main init_fn
