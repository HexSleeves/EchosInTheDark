open Tsdl
open Lwt.Infix

(* Modules *)
module S = State
module B = Backend
module R = Renderer

type 'a t =
  { render : 'a Lwt.t -> unit
  ; handle_tick : 'a -> 'a Lwt.t
  ; handle_event : 'a -> Event.t -> 'a Lwt.t * bool
  }

let timer () = Lwt_unix.sleep 0.1 >|= fun () -> `Timer

let main init_fn =
  let renderer = R.create 320 200 in
  let data, v = init_fn renderer in

	let rec update_loop data = 
		update_loop data in

	update_loop data


  (* let rec update_loop data =
    (* let rec event_loop data =
      let event =
        (* convert to our Event.t *)
        if Sdl.poll_event some_event then Event.of_sdl event else Event.NoEvent
      in
      match event with
      | Quit -> data, `Quit
      | NoEvent -> data, `NoEvent
      | EventNotRelevant ->
        (* Get rid of events we don't care about *)
        event_loop data
      | _ ->
        let time = Sdl.get_ticks () |> Int32.to_int in
        let data =
          if time - !last_tick_time > tick_wait_time
          then (
            last_tick_time := time;
            v.handle_tick data time)
          else data
        in
        let data, quit = v.handle_event data event in
        if quit then data, `Quit else event_loop data
    in *)

    (* first handle all events *)
    let data, response = event_loop data in
    match response with
    | `Quit -> ()
    | _ ->
      let time = Sdl.get_ticks () |> Int32.to_int in
      let tick_diff = time - !last_tick_time in
      
			let data = v.handle_tick data time
      in
			

			let%lwt data = v.handle_tick data time in

			v.render data;
      update_loop data
  in
  update_loop data *)
	[@@ocamlformat "disable"]
