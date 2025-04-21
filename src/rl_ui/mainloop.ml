open Base
open Modules_d
module S = State
module R = Renderer

type 'a t = {
  render : State.t -> (State.t, screen_update_error) Result.t;
  handle_tick : State.t -> State.t;
}

let draw_raylib_scene draw_func =
  let open Raylib in
  (* Use Fun.protect to ensure end_drawing is always called, even if an exception occurs *)
  Stdlib.Fun.protect
    ~finally:(fun () -> end_drawing ())
    (fun () ->
      begin_drawing ();
      clear_background Color.black;

      (* Main Draw fn *)
      let result = draw_func () in

      (* Return the result after drawing is complete *)
      result)

(* Main *)
let main init_fn =
  let font_config = R.create ~title:"Rougelike Tutorial 2025" () in
  let (data : State.t), v = init_fn font_config in

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

  (* Ensure cleanup always runs, even if an exception occurs during the update loop *)
  Stdlib.Fun.protect
    ~finally:(fun () ->
      Ui_log.info (fun m -> m "Cleaning up resources...");
      R.cleanup font_config)
    (fun () -> update_loop data)
