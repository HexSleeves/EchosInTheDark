open Base
open Modules_d
open State
open Screens
module R = Renderer

(* Core modules *)
module T = Rl_core.Types
module Core_State = Rl_core.State

type mainloop_iface = {
  render : State.t -> (State.t, screen_update_error) Result.t;
  handle_tick : State.t -> State.t;
}

(* Config for initializing the game state *)
type init_config = {
  width : int;
  height : int;
  debug : bool;
  seed : int option;
  font_config : Renderer.font_config;
  backend : Core_State.t option;
}

(* Handle tick updates based on current screen using the Screen interface *)
let handle_tick (s : State.t) =
  match s.screen with
  | MainMenu m ->
      let s', m' = MainMenuScreen.handle_tick m s in
      { s' with screen = MainMenu m' }
  | Playing -> PlayScreen.handle_tick s s |> fst
  | GameOver -> GameOverScreen.handle_tick s

(* Render current screen and return either new State or error using the Screen interface *)
let render (s : State.t) : (State.t, screen_update_error) Result.t =
  match s.screen with
  | MainMenu m -> (
      match MainMenuScreen.render m s with
      | Some (m', st) -> Ok { st with screen = MainMenu m' }
      | None -> Ok s)
  | Playing -> (
      match PlayScreen.render s s with Some (_, st) -> Ok st | None -> Ok s)
  | GameOver ->
      GameOverScreen.render s;
      Ok s

(* --- Begin mainloop.ml logic --- *)

let draw_raylib_scene draw_func =
  let open Raylib in
  Stdlib.Fun.protect
    ~finally:(fun () -> end_drawing ())
    (fun () ->
      begin_drawing ();
      clear_background Color.black;
      let result = draw_func () in
      result)

let main init_fn font_config =
  let (data : State.t), (v : mainloop_iface) = init_fn font_config in
  let rec update_loop (data : State.t) =
    match Raylib.window_should_close () || data.quitting with
    | true -> Ui_log.info (fun m -> m "Window closing...")
    | false ->
        let new_data = v.handle_tick data in
        if new_data.quitting then Ui_log.info (fun m -> m "Quitting...")
        else
          let draw_result = draw_raylib_scene (fun () -> v.render new_data) in
          let updated_data =
            match draw_result with
            | Ok st -> st
            | Error err ->
                Ui_log.err (fun m ->
                    m "Render error: %s"
                      (match err with
                      | StateUpdateError msg | RenderError msg -> msg));
                new_data
          in
          update_loop updated_data
  in
  Stdlib.Fun.protect
    ~finally:(fun () ->
      Ui_log.info (fun m -> m "Cleaning up resources...");
      R.cleanup font_config)
    (fun () -> update_loop data)
(* --- End mainloop.ml logic --- *)

(* Create initial game state using init_config *)
let create_initial_state (config : init_config) =
  let seed =
    Option.value config.seed ~default:(Rl_utils.Rng.generate_seed ())
  in
  let backend =
    match config.backend with
    | Some b -> b
    | None ->
        Core_State.make ~debug:config.debug ~w:config.width ~h:config.height
          ~seed
  in

  let current_map = Core_State.get_current_map backend in
  let player_start = current_map.player_start in

  let backend =
    (* Spawn player using Backend function. This handles entity creation,
     actor manager update, and scheduling the first turn. *)
    let sub_backend =
      Core_State.spawn_player ~pos:player_start ~direction:T.Direction.North
        backend
    in

    (* Spawn creature using Backend function. This handles entity/actor creation. *)
    let sub_backend =
      Core_State.spawn_creature sub_backend
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
    (state, { render; handle_tick })
  in
  main init_fn config.font_config
