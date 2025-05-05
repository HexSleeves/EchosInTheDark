open Base
open State_types

let setup_entities_for_level ~em ~actor_manager ~turn_queue =
  Entity_manager.all_entities em
  |> List.fold_left ~init:(actor_manager, turn_queue) ~f:(fun (am, tq) int ->
         let actor =
           match Components.Kind.get int with
           | Some Player -> Actor_manager.create_player_actor
           | Some Creature -> Actor_manager.create_rat_actor
           | _ -> failwith "Unknown entity kind"
         in

         match Turn_queue.is_scheduled tq int with
         | true -> (Actor_manager.add int actor am, tq)
         | false ->
             (Actor_manager.add int actor am, Turn_queue.schedule_at tq int 0))

let transition_to_next_level (state : State_types.t) : State_types.t =
  (* Save current chunk_manager *)
  let state =
    State_chunk.update_chunk_managers state.chunk_managers state.chunk_manager
      state
  in

  let next_depth = state.depth + 1 in

  (* Load or create chunk_manager for next level *)
  let chunk_manager =
    match Base.Hashtbl.find state.chunk_managers next_depth with
    | Some cm -> cm
    | None ->
        Chunk_manager.create ~world_seed:next_depth
          ~level:(Int.to_string next_depth)
  in

  let player_id =
    match Entity_manager.get_player_id state.em with
    | Some id -> id
    | None -> failwith "No player id found"
  in

  let state' =
    { state with depth = next_depth; chunk_manager } |> fun state' ->
    match Components.Position.get player_id with
    | Some pos -> (
        match Chunk_manager.get_tile_at pos.world_pos chunk_manager with
        | Some Dungeon.Tile.Stairs_up ->
            State_entities.move_entity player_id pos state'
        | _ -> state')
    | None -> state'
  in

  let chunk_manager, em =
    match Components.Position.get player_id with
    | Some pos ->
        Chunk_manager.tick state.em pos.world_pos chunk_manager
          ~depth:state'.depth
    | None -> (chunk_manager, state.em)
  in

  { state' with em; chunk_manager }

let transition_to_previous_level (state : State_types.t) : State_types.t =
  Base.Hashtbl.set state.chunk_managers ~key:state.depth
    ~data:state.chunk_manager;
  let prev_depth = state.depth - 1 in

  let chunk_manager =
    match Base.Hashtbl.find state.chunk_managers prev_depth with
    | Some cm -> cm
    | None ->
        Chunk_manager.create ~world_seed:prev_depth
          ~level:(Int.to_string prev_depth)
  in

  let player_id =
    match Entity_manager.get_player_id state.em with
    | Some id -> id
    | None -> failwith "No player id found"
  in

  let state' =
    { state with depth = prev_depth; chunk_manager } |> fun state' ->
    match Components.Position.get player_id with
    | Some pos -> (
        match Chunk_manager.get_tile_at pos.world_pos chunk_manager with
        | Some Dungeon.Tile.Stairs_down ->
            State_entities.move_entity player_id pos state'
        | _ -> state')
    | None -> state'
  in

  let chunk_manager, em =
    match Components.Position.get player_id with
    | Some pos ->
        Chunk_manager.tick state.em pos.world_pos chunk_manager
          ~depth:state'.depth
    | None -> (chunk_manager, state.em)
  in

  { state' with em; chunk_manager }
