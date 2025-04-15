module S = State
module B = Backend
module R = Renderer

type 'a t = {
  render : State.t -> State.t option;
  handle_tick : State.t -> State.t;
}

let draw_raylib_scene draw_func =
  let open Raylib in
  begin_drawing ();
  clear_background Color.black;

  (* Main Draw fn *)
  let result = draw_func () in

  (* Wrapup  *)
  end_drawing ();
  result

(* Main *)
let main init_fn =
  let font_config = R.create ~title:"Rougelike Tutorial 2023" () in
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
          match draw_raylib_scene (fun () -> v.render data) with
          | None -> update_loop data
          | Some render_data -> update_loop render_data)
  in

  update_loop data
