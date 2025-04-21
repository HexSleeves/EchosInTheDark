open Base
open Modules_d
open State
module R = Renderer

(* Core modules *)
module Actor = Rl_core.Actor
module Actions = Rl_core.Actions
module AM = Rl_core.Actor_manager
module B = Rl_core.Backend
module SP = Rl_core.Spawner
module T = Rl_core.Types
module Turn_queue = Rl_core.Turn_queue

(* Config for initializing the game state *)
type init_config = {
  font_config : Renderer.font_config;
  seed : int option;
  debug : bool;
  width : int;
  height : int;
  backend : Rl_core.Backend.t option;
}

(* Screen interface for all UI/game screens *)
module type Screen = sig
  type t

  val handle_tick : t -> State.t -> State.t * t
  val render : t -> State.t -> (t * State.t) option
end

(* MainMenu as a Screen *)
module MainMenuScreen : Screen with type t = Mainmenu.t = struct
  type t = Mainmenu.t

  let handle_tick m s =
    let new_mainmenu, result = Mainmenu.handle_tick m in
    match result with
    | Some Play -> ({ s with screen = Playing }, new_mainmenu)
    | Some Quit ->
        ( { s with quitting = true; screen = MainMenu new_mainmenu },
          new_mainmenu )
    | None -> ({ s with screen = MainMenu new_mainmenu }, new_mainmenu)

  let render m s =
    match Mainmenu.render m with
    | Some m' -> Some (m', { s with screen = MainMenu m' })
    | None -> None
end

(* Play as a Screen (stateless for now) *)
module PlayScreen : Screen with type t = State.t = struct
  type t = State.t

  let handle_tick _ s = (Play.handle_tick s, s)

  let render _ s =
    match Play.render s with Some s' -> Some (s', s') | None -> None
end

(* Convert an optional update into a Result, logging failures *)
let option_to_screen (s : State.t) (update : 'a option)
    (scrn_constructor : 'a -> screen) : (State.t, screen_update_error) Result.t
    =
  match update with
  | Some new_screen_state -> (
      try Ok { s with screen = scrn_constructor new_screen_state }
      with exn -> Error (StateUpdateError (Exn.to_string exn)))
  | None -> Ok s

(* Handle tick updates based on current screen using the Screen interface *)
let handle_tick (s : State.t) =
  match s.screen with
  | MainMenu m ->
      let s', m' = MainMenuScreen.handle_tick m s in
      { s' with screen = MainMenu m' }
  | Playing -> PlayScreen.handle_tick s s |> fst

(* Render current screen and return either new State or error using the Screen interface *)
let render (s : State.t) : (State.t, screen_update_error) Result.t =
  match s.screen with
  | MainMenu m -> (
      match MainMenuScreen.render m s with
      | Some (m', st) -> Ok { st with screen = MainMenu m' }
      | None -> Ok s)
  | Playing -> (
      match PlayScreen.render s s with Some (_, st) -> Ok st | None -> Ok s)

(* Create initial game state using init_config *)
let create_initial_state (config : init_config) =
  let seed =
    Option.value config.seed ~default:(Rl_utils.Rng.generate_seed ())
  in
  let backend =
    match config.backend with
    | Some b -> b
    | None -> B.make ~debug:config.debug ~w:config.width ~h:config.height ~seed
  in
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
  {
    quitting = false;
    screen = Playing;
    backend = { backend with actor_manager = am };
    font_config = config.font_config;
  }

let run_with_config (config : init_config) : unit =
  let init_fn _font_config =
    let state = create_initial_state config in
    (state, Mainloop.{ handle_tick; render })
  in
  Mainloop.main init_fn
