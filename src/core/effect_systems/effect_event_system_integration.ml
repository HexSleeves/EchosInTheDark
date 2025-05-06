(* Effect Event System Integration

   This module provides integration between the existing event system
   and the effect-based approach. It serves as a bridge that allows
   gradual adoption of effect handlers without disrupting the existing codebase.
*)

open Base
open Types

(* ========== Effect Types ========== *)

(* Effect for publishing an event *)
type _ Stdlib.Effect.t +=
  | Publish_event : Events.Event_bus.event -> unit Stdlib.Effect.t

(* Effect for subscribing to events *)
type _ Stdlib.Effect.t +=
  | Subscribe : (Events.Event_bus.event -> unit) -> unit Stdlib.Effect.t

(* Effect for subscribing to specific event categories *)
type _ Stdlib.Effect.t +=
  | Subscribe_category :
      Events.Event_bus.event_category list * (Events.Event_bus.event -> unit)
      -> unit Stdlib.Effect.t

(* ========== Handler Implementation ========== *)

(* Run a computation with event system handlers *)
let with_event_system (state : State.t) (f : unit -> 'a) : 'a * State.t =
  let state_ref = ref state in
  let result =
    Stdlib.Effect.Deep.try_with f ()
      {
        effc =
          (fun (type a) (eff : a Stdlib.Effect.t) ->
            match eff with
            | Publish_event event ->
                Some
                  (fun (k : (a, _) Stdlib.Effect.Deep.continuation) ->
                    state_ref := Events.Event_bus.publish event !state_ref;
                    Stdlib.Effect.Deep.continue k ())
            | Subscribe handler_fn ->
                Some
                  (fun (k : (a, _) Stdlib.Effect.Deep.continuation) ->
                    Events.Event_bus.subscribe (fun event state ->
                        handler_fn event;
                        state);
                    Stdlib.Effect.Deep.continue k ())
            | Subscribe_category (categories, handler_fn) ->
                Some
                  (fun (k : (a, _) Stdlib.Effect.Deep.continuation) ->
                    Events.Event_bus.subscribe_category categories
                      (fun event state ->
                        handler_fn event;
                        state);
                    Stdlib.Effect.Deep.continue k ())
            | _ -> None);
      }
  in
  (result, !state_ref)

(* ========== Utility Functions ========== *)

(* Publish an event *)
let publish_event event = Stdlib.Effect.perform (Publish_event event)

(* Subscribe to all events *)
let subscribe handler = Stdlib.Effect.perform (Subscribe handler)

(* Subscribe to specific event categories *)
let subscribe_category categories handler =
  Stdlib.Effect.perform (Subscribe_category (categories, handler))

(* Convenience functions for subscribing to specific event types *)
let subscribe_player_events handler =
  subscribe_category [ Events.Event_bus.PlayerEvent ] handler

let subscribe_movement_events handler =
  subscribe_category [ Events.Event_bus.MovementEvent ] handler

let subscribe_combat_events handler =
  subscribe_category [ Events.Event_bus.CombatEvent ] handler

(* Item and Stairs event subscription functions removed - functionality now in action_handler *)

(* ========== Integration Functions ========== *)

(* Run a function with event handlers and return the updated state *)
let run_with_events (state : State.t) (f : unit -> 'a) : State.t =
  let _, final_state = with_event_system state f in
  final_state

(* Publish an event and return the updated state *)
let publish_event_and_update (event : Events.Event_bus.event) (state : State.t)
    : State.t =
  run_with_events state (fun () -> publish_event event)

(* ========== Gradual Integration ========== *)

(* Example: Movement event handler using effects *)
let handle_movement_events () =
  subscribe_movement_events (function
    | Events.Event_bus.EntityMoved { entity_id; from_pos; to_pos } ->
        Core_log.info (fun m ->
            m "Entity %d moved from (%d,%d) to (%d,%d)" entity_id
              from_pos.world_pos.x from_pos.world_pos.y to_pos.world_pos.x
              to_pos.world_pos.y)
    | Events.Event_bus.EntityWantsToMove { entity_id; dir } ->
        Core_log.info (fun m ->
            m "Entity %d wants to move %s" entity_id (Direction.show dir))
    | _ -> ())

(* Example: Combat event handler using effects *)
let handle_combat_events () =
  subscribe_combat_events (function
    | Events.Event_bus.EntityAttacked { attacker_id; defender_id } ->
        Core_log.info (fun m ->
            m "Entity %d attacked entity %d" attacker_id defender_id)
    | Events.Event_bus.ActorDamaged { actor_id; amount } ->
        Core_log.info (fun m -> m "Actor %d took %d damage" actor_id amount)
    | Events.Event_bus.EntityDied { entity_id } ->
        Core_log.info (fun m -> m "Entity %d died" entity_id)
    | _ -> ())

(* Initialize event handlers using effects *)
let init (state : State.t) : State.t =
  run_with_events state (fun () ->
      handle_movement_events ();
      handle_combat_events ();

      (* Example of a custom event handler that updates state *)
      subscribe (function
        | Events.Event_bus.EntityDied { entity_id } ->
            Core_log.info (fun m ->
                m "Custom handler: Entity %d died" entity_id)
        | _ -> ()))
