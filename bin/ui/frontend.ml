open Containers
module B = Backend

let run () : unit =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Info);

  Printf.printf "initializing frontend...";
  print_newline ();

  let init_fn win =
    let create_state ?backend ?ui_options ?ui_view screen =
      let backend =
        match backend with
        | Some b -> b
        | None ->
            (* Used by different elements *)
            Random.self_init ();
            let random = Random.get_state () in
            let seed = Random.int 0x7FFF random in
            B.default ~random ~seed
      in

      let _ = ui_options in
      let _ = ui_view in
      let _ = win in
      { State.screen; backend }
    in

    let state = create_state (Screen.MapGen None) in

    Printf.printf "initialization done.\n";

    state
  in

  Mainloop.main init_fn
