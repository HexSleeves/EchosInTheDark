open Base
open Modules_d
module R = Renderer

(* Core modules *)
module Actor = Rl_core.Actor
module Actions = Rl_core.Actions
module AM = Rl_core.Actor_manager
module B = Rl_core.Backend
module SP = Rl_core.Spawner
module T = Rl_core.Types
module Turn_queue = Rl_core.Turn_queue

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
      | Some Play -> { s with screen = Playing }
      | Some Quit -> { s with quitting = true; screen = MainMenu new_mainmenu }
      | None -> { s with screen = MainMenu new_mainmenu })
  | Playing -> Play.handle_tick s

(* Render current screen and return optional updated state *)
let render (s : State.t) : State.t option =
  match s.screen with
  | MainMenu m ->
      option_to_screen s (Mainmenu.render m) (fun x -> Modules_d.MainMenu x)
  | Playing -> option_to_screen s (Play.render s) (fun _ -> Modules_d.Playing)

(* Create initial game state *)
let create_initial_state font_config =
  let create_state ?backend screen =
    let seed = Rl_utils.Rng.generate_seed () in

    let backend =
      match backend with
      | Some b -> b
      | None -> B.make ~debug:true ~w:80 ~h:50 ~seed
    in

    { font_config; State.screen; quitting = false; backend }
  in
  let state = create_state Playing in

  let backend = state.backend in
  let em = backend.Rl_core.Backend.entities in
  let tq = backend.Rl_core.Backend.turn_queue in
  let am = backend.Rl_core.Backend.actor_manager in
  let player_id = backend.Rl_core.Backend.player.entity_id in

  (* Add to turn queue *)
  Turn_queue.schedule_turn tq player_id 0;

  (* Add to actor manager *)
  let player_actor = Actor.create ~speed:100 ~next_turn_time:0 in
  AM.add am player_id player_actor;

  (* Spawn player *)
  let player_start = backend.Rl_core.Backend.map.player_start in
  SP.spawn_player em ~pos:player_start ~direction:T.North ~actor_id:player_id;

  Logs.info (fun m -> m "Initialization done.");
  { state with backend = { state.backend with actor_manager = am } }

(* Initialize logging *)
let setup_logging () =
  Logs.set_level (Some Debug);
  Logs.info (fun m -> m "Loading resources...")

(* Run the game *)
let run () : unit =
  setup_logging ();

  let init_fn font_config =
    let state = create_initial_state font_config in
    (state, Mainloop.{ handle_tick; render })
  in
  Mainloop.main init_fn
