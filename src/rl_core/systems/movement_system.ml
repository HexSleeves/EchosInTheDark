open Base
open Events.Event_bus
open Components
open Types

let move_entity ~(id : int) ~(to_pos : Loc.t) (state : State_types.t) :
    State_types.t =
  let from_pos =
    State.get_entity id state
    |> Option.map ~f:Entity.get_id
    |> Option.bind ~f:Position.get
    |> Option.value ~default:to_pos
  in

  (* Update the Position component table *)
  State.move_entity id to_pos state
  |> publish (EntityMoved { entity_id = id; from_pos; to_pos })
