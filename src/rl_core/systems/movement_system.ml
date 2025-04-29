open Base
open Events.Event_bus
open Components
open Types

let move_entity ~(entity_id : entity_id) ~(to_pos : Loc.t)
    (state : State_types.t) : State_types.t =
  let from_pos = entity_id |> Position.get |> Option.value ~default:to_pos in

  (* Update the Position component table *)
  State.move_entity entity_id to_pos state
  |> publish (EntityMoved { entity_id; from_pos; to_pos })
