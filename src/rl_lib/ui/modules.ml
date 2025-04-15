open Modules_d

(* Main modules of game. They don't carry much state between them *)
module R = Renderer
module B = Backend
module E = Entity
module P = Pos

(* Helper to convert optional screen update to State.t option *)
let option_to_screen (s : State.t) (update : 'a option)
    (scrn_constructor : 'a -> Modules_d.screen) : State.t option =
  match update with
  | Some new_screen_state ->
      Some { s with screen = scrn_constructor new_screen_state }
  | None -> None

(* Handle tick updates based on current screen *)
let handle_tick (s : State.t) =
  match s.screen with
  | MainMenu m -> (
      let new_mainmenu, result = Mainmenu.handle_tick m in
      match result with
      | Some Play -> { s with screen = MapGen Mapgen.init }
      | Some Quit -> { s with quitting = true; screen = MainMenu new_mainmenu }
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
  | Playing -> Play.handle_tick s

(* Render current screen and return optional updated state *)
let render (s : State.t) : State.t option =
  match s.screen with
  | MapGen m ->
      option_to_screen s (Mapgen.render m) (fun x -> Modules_d.MapGen x)
  | MainMenu m ->
      option_to_screen s (Mainmenu.render m) (fun x -> Modules_d.MainMenu x)
  | Playing -> option_to_screen s (Play.render s) (fun _ -> Modules_d.Playing)

(* Initialize logging *)
let setup_logging () =
  Logs.set_level (Some Debug);
  Logs.info (fun m -> m "Loading resources...")

(* Create initial game state *)
let create_initial_state font_config =
  let create_state ?backend screen =
    let backend =
      match backend with
      | Some b -> b
      | None ->
          let b = B.make_default ~debug:true in
          B.update b ~w:60 ~h:39 ~seed:0
    in
    { backend; font_config; State.screen; quitting = false }
  in
  let state = create_state Playing in

  let backend = state.backend in
  let em = backend.entities in
  let tq = backend.turn_queue in
  let am = backend.actor_manager in
  let player_id = backend.player.entity_id in

  (* Add to turn queue *)
  Turn_queue.schedule_turn tq 0 100;

  (* Add to actor manager *)
  let player_actor = Actor.create ~speed:100 ~next_turn_time:100 in
  Actor_manager.add am player_id player_actor;

  (* Spawn player *)
  Spawner.spawn_player em ~pos:(1, 1) ~direction:P.North ~actor_id:player_id;

  Logs.info (fun m -> m "Initialization done.");
  { state with backend = { backend with actor_manager = am } }

(* Run the game *)
let run () : unit =
  setup_logging ();
  let init_fn font_config =
    let state = create_initial_state font_config in
    (state, Mainloop.{ handle_tick; render })
  in
  Mainloop.main init_fn
