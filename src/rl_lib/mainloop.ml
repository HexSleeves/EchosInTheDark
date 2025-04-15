module S = State
module B = Backend
module R = Renderer

type 'a t = {
  render : State.t -> State.t option;
  handle_tick : State.t -> State.t;
}

let draw_raylib_scene draw_func =
  let open Raylib in
  (* Use Fun.protect to ensure end_drawing is always called, even if an exception occurs *)
  Fun.protect
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
    | true -> Log.info "Window closing..."
    | false ->
        let new_data = v.handle_tick data in
        if new_data.quitting then Log.info "Quitting..."
        else
          let updated_data =
            match draw_raylib_scene (fun () -> v.render new_data) with
            | None -> new_data
            | Some render_data -> render_data
          in
          update_loop updated_data
  in

  (* Ensure cleanup always runs, even if an exception occurs during the update loop *)
  Fun.protect
    ~finally:(fun () ->
      Log.info "Cleaning up resources...";
      R.cleanup font_config)
    (fun () -> update_loop data)
