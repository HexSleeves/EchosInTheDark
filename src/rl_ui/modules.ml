open Base
open Modules_d
module R = Renderer
module B = Rl_core.Backend
module E = Rl_core.Entity
module T = Rl_core.Types
module A = Rl_core.Actor
module AM = Rl_core.Actor_manager
module Actions = Rl_core.Actions
module Turn_queue = Rl_core.Turn_queue
module SP = Rl_core.Spawner

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
            game_state =
              (let backend =
                 B.make ~debug:true ~w:mapgen.width ~h:mapgen.height
                   ~seed:mapgen.seed
               in

               let open Rl_core.State in
               let multi_level =
                 let total_levels = 3 in
                 (* TODO: get from config *)
                 let maps = Base.Hashtbl.create (module Int) in
                 Base.Hashtbl.set maps ~key:1 ~data:backend.map;
                 MultiLevelState.
                   {
                     maps;
                     total_levels;
                     current_level = 1;
                     player_has_amulet = false;
                   }
               in
               { backend; multi_level });
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

(* Create initial game state *)
let create_initial_state font_config =
  let create_state ?backend screen =
    let seed = Rl_utils.Rng.seed_int in
    let backend =
      match backend with
      | Some b -> b
      | None -> B.make ~debug:true ~w:80 ~h:50 ~seed
    in
    let open Rl_core.State in
    let multi_level =
      let total_levels = 3 in
      (* TODO: get from config *)
      let maps = Base.Hashtbl.create (module Int) in
      Base.Hashtbl.set maps ~key:1 ~data:backend.map;
      MultiLevelState.
        { current_level = 1; total_levels; maps; player_has_amulet = false }
    in
    let game_state = { backend; multi_level } in
    { game_state; font_config; State.screen; quitting = false }
  in
  let state = create_state Playing in

  let backend = state.game_state.backend in
  let em = backend.Rl_core.Backend.entities in
  let tq = backend.Rl_core.Backend.turn_queue in
  let am = backend.Rl_core.Backend.actor_manager in
  let player_id = backend.Rl_core.Backend.player.entity_id in

  (* Add to turn queue *)
  Turn_queue.schedule_turn tq player_id 0;

  (* Add to actor manager *)
  let player_actor = A.create ~speed:100 ~next_turn_time:0 in
  AM.add am player_id player_actor;

  (* Spawn player *)
  let player_start = backend.Rl_core.Backend.map.player_start in
  SP.spawn_player em ~pos:player_start ~direction:T.North ~actor_id:player_id;

  Logs.info (fun m -> m "Initialization done.");
  {
    state with
    game_state =
      { state.game_state with backend = { backend with actor_manager = am } };
  }

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
