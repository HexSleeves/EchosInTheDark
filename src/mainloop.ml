(* Modules *)
module S = State
module B = Backend
module R = Renderer
module G = Grafx

type 'a t = {
  render : State.t -> unit;
  handle_tick : State.t -> State.t;
  handle_event : State.t -> State.t * bool;
}

(* Main *)
let main init_fn =
  let font = R.create 80 50 in
  let data, v = init_fn font in

  let rec update_loop data =
    match Raylib.window_should_close () with
    | true -> Raylib.close_window ()
    | false -> (
        let open Raylib in
        (* Events *)
        let data, quit = v.handle_event data in

        match quit with
        | true -> ()
        | _ ->
            (* Ticks *)
            let data = v.handle_tick data in

            (* Render *)
            G.draw_raylib_scene (fun () -> v.render data);

            update_loop data)
  in

  update_loop data
