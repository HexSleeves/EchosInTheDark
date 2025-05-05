open Components

let handle_event (event : Events.Event_bus.t) (state : State_types.t) :
    State_types.t =
  match event with
  | Events.Event_bus.StairsUp { entity_id } -> (
      let pos = Position.get_exn entity_id in
      match State.get_tile_at state pos.world_pos with
      | Some tile when Dungeon.Tile.equal tile Dungeon.Tile.Stairs_up ->
          State.transition_to_previous_level state
      | _ -> state)
  | Events.Event_bus.StairsDown { entity_id } -> (
      let pos = Position.get_exn entity_id in
      match State.get_tile_at state pos.world_pos with
      | Some tile when Dungeon.Tile.equal tile Dungeon.Tile.Stairs_down ->
          State.transition_to_next_level state
      | _ -> state)
  | _ -> state

let init () = Events.Event_bus.subscribe_stairs_events handle_event
