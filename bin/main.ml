(* open Effect
   open Effect.Deep
   open Notty
   open Notty_unix

   type cell = Empty | Cactus | Camel | Snake | Elephant | Spider | Spider_egg

   let width, height = (50, 30)
   let world = Array.make_matrix width height Empty
   let get (x, y) = try world.(x).(y) with _ -> Cactus
   let set (x, y) v = world.(x).(y) <- v

   (*  *)
   let () = Random.self_init ()
   let random_position () = (Random.int width, Random.int height)

   let () =
     for _ = 0 to 200 do
       set (random_position ()) Cactus
     done;
     for _ = 0 to 20 do
       set (random_position ()) Snake
     done;
     for _ = 0 to 10 do
       set (random_position ()) Elephant
     done;
     for _ = 0 to 3 do
       set (random_position ()) Spider
     done

   let camel_initial_position = random_position ()
   let () = set camel_initial_position Camel

   let string_of_cell = function
     | Empty -> "  "
     | Cactus -> "\u{1F335}"
     | Camel -> "\u{1F42A}"
     | Snake -> "\u{1F40D}"
     | Elephant -> "\u{1F418}"
     | Spider -> "\u{1F577} "
     | Spider_egg -> "\u{1F95A}"

   let draw_cell c = I.string A.empty (string_of_cell c)

   let draw_world () =
     I.hcat @@ Array.to_list
     @@ Array.map
          (fun column -> I.vcat @@ Array.to_list @@ Array.map draw_cell column)
          world

   let terminal = Term.create ()
   let render () = Term.image terminal (draw_world ())

   type _ Effect.t += End_of_turn : unit Effect.t

   let queue : (unit -> unit) Queue.t = Queue.create ()

   let player character =
     match_with character ()
       {
         effc =
           (fun (type b) (eff : b t) ->
             match eff with
             | End_of_turn ->
                 Some
                   (fun (k : (b, _) continuation) ->
                     Queue.add (fun () -> continue k ()) queue)
             | _ -> None);
         retc = (fun result -> result);
         exnc = (fun e -> raise e);
       }

   let spawn child = Queue.add (fun () -> player child) queue

   let run_queue () =
     while true do
       render ();
       let suspended_character = Queue.pop queue in
       suspended_character ()
     done

   let keyboard_direction () =
     match Term.event terminal with
     | `Key (`Escape, _) -> exit 0 (* press <escape> to quit *)
     | `Key (`Arrow `Left, _) -> (-1, 0)
     | `Key (`Arrow `Right, _) -> (1, 0)
     | `Key (`Arrow `Down, _) -> (0, 1)
     | `Key (`Arrow `Up, _) -> (0, -1)
     | _ -> (0, 0)

   let ( ++ ) (x, y) (dx, dy) = (x + dx, y + dy)

   let move old_position new_position =
     match get new_position with
     | Empty ->
         let character = get old_position in
         set old_position Empty;
         set new_position character;
         new_position
     | _ -> old_position

   let rec camel current_position =
     let new_position = current_position ++ keyboard_direction () in
     let new_position = move current_position new_position in
     perform End_of_turn;
     camel new_position

   let all_directions = [ (1, 0); (-1, 0); (0, 1); (0, -1) ]

   let random_direction () =
     List.nth all_directions (Random.int @@ List.length all_directions)

   let random_move old_pos =
     let new_pos = move old_pos (old_pos ++ random_direction ()) in
     perform End_of_turn;
     new_pos

   let snake initial_pos : unit =
     let pos = ref initial_pos in
     while true do
       pos := random_move !pos
     done

   let rec spider pos =
     try_to_lay_egg pos;
     let new_pos = random_move pos in
     spider new_pos

   and try_to_lay_egg pos =
     let egg_pos = pos ++ random_direction () in
     if get egg_pos = Empty && Random.int 100 = 0 then (
       set egg_pos Spider_egg;
       spawn (fun () -> egg egg_pos))

   and egg pos =
     for _ = 1 to 10 do
       perform End_of_turn
     done;

     for dx = -1 to 1 do
       for dy = -1 to 1 do
         let child_pos = pos ++ (dx, dy) in
         if get child_pos = Empty then (
           set child_pos Spider;
           spawn (fun () -> spider child_pos))
       done
     done

   let rec camel_in_sight pos direction =
     let next_pos = pos ++ direction in
     match get next_pos with
     | Camel -> true
     | Empty -> camel_in_sight next_pos direction
     | _ -> false

   let camel_in_sight pos = List.find_opt (camel_in_sight pos) all_directions

   let rec elephant pos : unit =
     match camel_in_sight pos with
     | None -> elephant (random_move pos)
     | Some direction ->
         let rec charge pos =
           let next_pos = pos ++ direction in
           match get next_pos with
           | Empty ->
               let next_pos = move pos next_pos in
               perform End_of_turn;
               charge next_pos
           | Cactus ->
               for _ = 1 to 20 do
                 perform End_of_turn (* knocked out! do nothing for 20 turns *)
               done;
               pos
           | _ ->
               perform End_of_turn;
               pos
         in

         let pos_after = charge pos in
         elephant pos_after

   (* exception Dead *)
   (* exception Hit *)

   (* let end_of_turn life =
      let previous_life = !life in
      perform End_of_turn;
      if !life <= 0 then raise Dead;
      if !life < previous_life then raise Hit *)

   let () =
     world
     |> Array.iteri @@ fun x ->
        Array.iteri @@ fun y -> function Camel -> spawn (fun () -> camel (x, y))
        | Spider -> spawn (fun () -> spider (x, y))
        | Elephant -> spawn (fun () -> elephant (x, y))
        | Snake -> spawn (fun () -> snake (x, y)) | _ -> ()

   let () = run_queue () *)

(* let finalize s = Io.save_to_file s "game.save" *)

let rec main_loop mode_state prev_ticks was_dead =
  let _ = (was_dead, prev_ticks) in

  let ticks = Int.of_float (Raylib.get_time ()) in

  let dead_now =
    match mode_state with
    | State.Play s -> (
        match s.State.cm with State.CtrlM.Died _ -> true | _ -> false)
    | _ -> false
  in

  let mode_state' =
    match mode_state with State.Play s -> State.Play s | ms -> ms
  in

  (* let prev_ticks = if was_dead && not dead_now then ticks else prev_ticks in *)
  let is_dead = dead_now in

  View.draw_scene (fun () ->
      match mode_state with
      | State.Play s ->
          (* draw_state ticks s; *)
          Printf.printf "ticks: %b\n" s.State.debug;

          (* FPS *)
          if s.State.debug then Raylib.draw_fps 0 0
      | _ -> ());

  if mode_state' <> State.Exit then
    match Raylib.window_should_close () with
    (* Keep Playing *)
    | false -> main_loop mode_state' ticks is_dead
    | true ->
        (* on exit *)
        (* (match mode_state' with State.Play s -> finalize s | _ -> ()); *)
        main_loop State.Exit ticks is_dead

let () =
  Random.self_init ();
  let args = Rl2023.Cli.parse in
  let title = Printf.sprintf "RL2023 - %dx%d" args.width args.height in
  let _ = (title, main_loop) in

  let state =
    let s =
      if Array.length Sys.argv > 1 then
        let s_prelim = Sys.argv.(1) in

        let opt_seed = if s_prelim = "?" then None else Some s_prelim in

        State.init_full opt_seed args.debug
      else if Sys.file_exists "game.save" then Io.load_from_file "game.save"
      else State.init_full None args.debug
    in

    State.Play s
  in

  Raylib.init_window args.width args.height title;
  Raylib.set_target_fps args.fps;
  Raylib.set_exit_key Raylib.Key.Escape;

  main_loop state (Int.of_float (Raylib.get_time ())) false
