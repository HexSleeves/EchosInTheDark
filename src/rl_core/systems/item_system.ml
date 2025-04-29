open Base
open Types
open Entities
open Components

let handle_event (event : Events.Event_bus.t) (state : State_types.t) :
    State_types.t =
  match event with
  | Events.Event_bus.ItemPickedUp { player_id; entity } -> (
      match (State.get_entity player_id state, entity) with
      | Some (Entity.Player (base, pdata)), Entity.Item (_, { item }) ->
          let inv = pdata.inventory in
          if not (Inventory.can_add_item inv) then state
          else
            let inv' =
              match Inventory.add_item inv item with
              | Ok inv' -> inv'
              | Error _ -> inv
            in

            let entities =
              Entity_manager.update player_id
                (fun _ -> Entity.Player (base, { pdata with inventory = inv' }))
                (State.get_entities_manager state)
              |> Entity_manager.remove item.id
            in
            State.set_entities_manager entities state
      | _ -> state)
  | Events.Event_bus.ItemDropped { player_id; entity } -> (
      match[@warning "-8"] (State.get_entity player_id state, entity) with
      | Some (Entity.Player (base, pdata)), Entity.Item (item_base, { item })
        -> (
          match Inventory.remove_item pdata.inventory item with
          | Error _ -> state
          | Ok inv' ->
              let pdata' = { pdata with inventory = inv' } in
              let idata' = Entity.Item (item_base, { item }) in
              let state' =
                State.move_entity item_base.id
                  (Components.Position.get_exn player_id)
                  state
              in

              let entities =
                Entity_manager.update player_id
                  (fun _ -> Entity.Player (base, pdata'))
                  (State.get_entities_manager state')
                |> Entity_manager.add idata'
              in
              State.set_entities_manager entities state'))
  | _ -> state

let () = Events.Event_bus.subscribe handle_event
