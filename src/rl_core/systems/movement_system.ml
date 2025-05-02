open Base
open Events.Event_bus
open Components
open Rl_types

let move_entity ~(entity_id : int) ~(go_to : Loc.t) (state : State_types.t) :
    State_types.t =
  let from_pos = Position.get_exn entity_id in
  let to_pos = Chunk_manager.make_position go_to in

  (* Update the Position component table *)
  State.move_entity entity_id to_pos state
  |> publish (EntityMoved { entity_id; from_pos; to_pos })
