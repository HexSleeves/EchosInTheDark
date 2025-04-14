module S = State
module B = Backend
module R = Renderer
module G = Grafx

type 'a t = {
  render : State.t -> State.t option;
  handle_tick : State.t -> State.t;
}

(* Main *)
let main init_fn =
  let font_config = R.create ~title:"Rougelike Tutorial 2023" 20 20 in
  let data, v = init_fn font_config in

  let rec update_loop data =
    match Raylib.window_should_close () with
    | true -> Raylib.close_window ()
    | false -> (
        (* Ticks *)
        let data = v.handle_tick data in
        if data.quitting then Printf.printf "Quitting...\n"
        else
          (* Render *)
          match G.draw_raylib_scene (fun () -> v.render data) with
          | None -> update_loop data
          | Some render_data -> update_loop render_data)
  in

  update_loop data
