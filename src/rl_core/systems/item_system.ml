open Base
open Components

let handle_event (event : Events.Event_bus.t) (state : State_types.t) :
    State_types.t =
  match event with
  | Events.Event_bus.ItemPickedUp { player_id; item_id } -> (
      match Kind.get player_id with
      | Some Kind.Player -> (
          match Inventory.get player_id with
          | None -> state
          | Some inv -> (
              match Inventory.can_add_item inv with
              | false -> state
              | true ->
                  let inv' =
                    match Inventory.add_item inv item_id with
                    | Ok inv' -> inv'
                    | Error _ -> inv
                  in

                  Components.Inventory.set player_id inv';

                  state))
      | None -> state
      | _ -> state)
  | Events.Event_bus.ItemDropped { player_id; item_id } -> (
      match[@warning "-8"] Kind.get player_id with
      | Some Kind.Player -> (
          match Inventory.get player_id with
          | None -> state
          | Some inv -> (
              match Inventory.remove_item inv item_id with
              | Error _ -> state
              | Ok inv' -> (
                  Components.Inventory.set player_id inv';

                  match Item.get item_id with
                  | Some item ->
                      State.move_entity item.id
                        (Components.Position.get_exn player_id)
                        state
                  | None -> state))))
  | _ -> state

let init () = Events.Event_bus.subscribe handle_event
