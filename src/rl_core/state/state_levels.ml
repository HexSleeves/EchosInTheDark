open Base
open Entities
open Actors
open State_types

let setup_entities_for_level ~entities ~actor_manager ~turn_queue =
  Entity_manager.to_list entities
  |> List.fold_left ~init:(actor_manager, turn_queue)
       ~f:(fun (am, tq) entity_id ->
         let actor =
           match Components.Kind.get entity_id with
           | Some Player -> Actor_manager.create_player_actor
           | Some Creature -> Actor_manager.create_rat_actor
           | _ -> failwith "Unknown entity kind"
         in

         match Turn_queue.is_scheduled tq entity_id with
         | true -> (Actor_manager.add entity_id actor am, tq)
         | false ->
             ( Actor_manager.add entity_id actor am,
               Turn_queue.schedule_at tq entity_id 0 ))

let transition_to_next_level (state : State_types.t) : State_types.t =
  (* Save current chunk_manager *)
  (* Base.Hashtbl.set state.chunk_managers ~key:state.depth
    ~data:state.chunk_manager; *)
  let state = State.update_chunk_managers state.chunk_managers state in

  let next_depth = state.depth + 1 in

  (* Load or create chunk_manager for next level *)
  let chunk_manager =
    match Base.Hashtbl.find state.chunk_managers next_depth with
    | Some cm -> cm
    | None -> Chunk_manager.create ~world_seed:next_depth
  in

  let state' =
    { state with depth = next_depth; chunk_manager } |> fun state' ->
    match Components.Position.get state'.player_id with
    | Some pos -> (
        match Chunk_manager.get_tile_at pos chunk_manager with
        | Some Dungeon.Tile.Stairs_up ->
            State_entities.move_entity state'.player_id pos state'
        | _ -> state')
    | None -> state'
  in

  {
    state' with
    chunk_manager =
      (match Components.Position.get state'.player_id with
      | Some pos -> Chunk_manager.tick pos chunk_manager ~depth:state'.depth
      | None -> chunk_manager);
  }

let transition_to_previous_level (state : State_types.t) : State_types.t =
  Base.Hashtbl.set state.chunk_managers ~key:state.depth
    ~data:state.chunk_manager;
  let prev_depth = state.depth - 1 in

  let chunk_manager =
    match Base.Hashtbl.find state.chunk_managers prev_depth with
    | Some cm -> cm
    | None -> Chunk_manager.create ~world_seed:prev_depth
  in

  let state' =
    { state with depth = prev_depth; chunk_manager } |> fun state' ->
    match Components.Position.get state'.player_id with
    | Some pos -> (
        match Chunk_manager.get_tile_at pos chunk_manager with
        | Some Dungeon.Tile.Stairs_down ->
            State_entities.move_entity state'.player_id pos state'
        | _ -> state')
    | None -> state'
  in

  {
    state' with
    chunk_manager =
      (match Components.Position.get state'.player_id with
      | Some pos -> Chunk_manager.tick pos chunk_manager ~depth:state'.depth
      | None -> chunk_manager);
  }
