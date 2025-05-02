open Base

let rebuild_position_index (state : State_types.t) : State_types.t =
  Hashtbl.clear state.position_index;
  Entities.Entity_manager.to_list state.entities
  |> List.iter ~f:(fun int ->
         match Components.Position.get int with
         | None -> ()
         | Some pos ->
             Hashtbl.set state.position_index ~key:pos.world_pos ~data:(int, pos));
  state
