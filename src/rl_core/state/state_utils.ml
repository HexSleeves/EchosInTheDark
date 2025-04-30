open Base

let rebuild_position_index (state : State_types.t) : State_types.t =
  Hashtbl.clear state.position_index;
  Entities.Entity_manager.to_list state.entities
  |> List.iter ~f:(fun entity_id ->
         match Components.Position.get entity_id with
         | None -> ()
         | Some pos ->
             Hashtbl.set state.position_index ~key:pos.world_pos
               ~data:(entity_id, pos));
  state
