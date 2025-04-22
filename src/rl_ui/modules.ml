open Base
open Modules_d
open State
open Screens
module R = Renderer

(* Core modules *)
module B = Rl_core.Backend
module T = Rl_core.Types

(* Config for initializing the game state *)
type init_config = {
  width : int;
  height : int;
  debug : bool;
  seed : int option;
  font_config : Renderer.font_config;
  backend : Rl_core.Backend.t option;
}

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

  let current_map = B.get_current_map backend in
  let player_start = current_map.player_start in

  let backend =
    (* Spawn player using Backend function. This handles entity creation,
     actor manager update, and scheduling the first turn. *)
    let sub_backend =
      B.spawn_player ~pos:player_start ~direction:T.Direction.North backend
    in

    (* Spawn creature using Backend function. This handles entity/actor creation. *)
    let sub_backend =
      B.spawn_creature sub_backend
        ~pos:(T.Loc.add player_start (T.Loc.make 1 1))
        ~direction:T.Direction.North ~species:"Rat" ~health:10 ~glyph:"r"
        ~name:"Rat" ~actor_id:1 ~description:"A small, brown rodent."
    in
    sub_backend
  in

  Logs.info (fun m -> m "Initialization done.");
  {
    quitting = false;
    screen = Playing;
    font_config = config.font_config;
    backend;
    (* Use the updated backend returned by the spawn functions *)
  }

let run_with_config (config : init_config) : unit =
  let init_fn _ =
    let state = create_initial_state config in
    (state, Mainloop.{ handle_tick; render })
  in
  Mainloop.main init_fn config.font_config
