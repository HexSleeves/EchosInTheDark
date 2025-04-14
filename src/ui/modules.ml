open Modules_d
open Types

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
        let mapgen = Mapgen.handle_tick m in
        match mapgen.action with
        | Some `Continue ->
            {
              s with
              screen = Playing;
              backend =
                B.update s.backend ~w:mapgen.width ~h:mapgen.height
                  ~seed:mapgen.seed;
            }
        | Some `Back -> { s with screen = MainMenu Mainmenu.init }
        | None -> { s with screen = MapGen mapgen })
    | Playing -> (
        let open Raylib in
        let dir_opt =
          if is_key_down Key.W || is_key_down Key.Up then Some North
          else if is_key_down Key.S || is_key_down Key.Down then Some South
          else if is_key_down Key.A || is_key_down Key.Left then Some West
          else if is_key_down Key.D || is_key_down Key.Right then Some East
          else None
        in
        match dir_opt with
        | Some dir -> { s with backend = Backend.move_player s.backend dir }
        | None -> s)
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
  Logs.set_level (Some Debug);

  (Logs.info @@ fun m -> m "Loading resources...");

  (* Initialize Game *)
  let init_fn font_config =
    let create_state ?backend screen =
      let backend =
        match backend with
        | Some b -> b
        | None ->
            let b = B.make_default ~debug:true in
            B.update b ~w:20 ~h:20 ~seed:0
      in

      { backend; font_config; State.screen; quitting = false }
    in

    (* Let's Roll *)
    let state = create_state Playing in
    (Logs.info @@ fun m -> m "initialization done.");
    (state, Mainloop.{ handle_tick; render })
  in
  Mainloop.main init_fn
