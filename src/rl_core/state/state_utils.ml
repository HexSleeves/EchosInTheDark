open Base

let rebuild_position_index (state : State_types.t) : State_types.t =
  Base.Hashtbl.clear state.position_index;
  Entities.Entity_manager.to_list state.entities
  |> List.iter ~f:(fun entity ->
         let id = Types.Entity.get_id entity in
         match Components.Position.get id with
         | Some pos -> Base.Hashtbl.set state.position_index ~key:pos ~data:id
         | None -> ());
  state
