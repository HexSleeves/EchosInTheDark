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
  let font = R.create 80 50 in
  let data, v = init_fn font in

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
          | Some render_data ->
              Printf.sprintf "[Render data]: %s\n"
                (match render_data.screen with
                | MainMenu _ -> "MainMenu"
                | MapGen s ->
                    Printf.sprintf "MapGen %s"
                      (match s.focus with
                      | `Width -> "Width"
                      | `Height -> "Height"
                      | `Seed -> "Seed"
                      | `None -> "None")
                | Playing -> "Playing")
              |> Stdio.print_endline;
              update_loop render_data)
  in

  update_loop data
