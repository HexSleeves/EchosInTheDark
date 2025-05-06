(* Effect-based Event System

   This module demonstrates how to use effect handlers to simplify
   the event system in the game.
*)

open Base
open Types
open Stdlib

(* Define our own logging functions *)
let log_info msg = Core_log.info (fun m -> m "%s" msg)
let log_debug msg = Core_log.debug (fun m -> m "%s" msg)
let log_warn msg = Core_log.warn (fun m -> m "%s" msg)
let log_error msg = Core_log.err (fun m -> m "%s" msg)

(* Define a simple update_state function *)
let update_state f state = f state

module Log = (val Core_log.make_logger "effect_event_system" : Logs.LOG)

(* Effect for subscribing to events *)
type _ Effect.t += Subscribe : (Events.Event_bus.event -> unit) -> unit Effect.t

(* Effect for subscribing to specific event categories *)
type _ Effect.t +=
  | Subscribe_category :
      Events.Event_bus.event_category list * (Events.Event_bus.event -> unit)
      -> unit Effect.t

(* Handler for event system effects *)
let with_event_system (f : unit -> 'a) : 'a = f ()

(* Subscribe to all events *)
let subscribe handler = Effect.perform (Subscribe handler)

(* Subscribe to specific event categories *)
let subscribe_category categories handler =
  Effect.perform (Subscribe_category (categories, handler))

(* Convenience functions for subscribing to specific event types *)
let subscribe_player_events handler =
  subscribe_category [ Events.Event_bus.PlayerEvent ] handler

let subscribe_movement_events handler =
  subscribe_category [ Events.Event_bus.MovementEvent ] handler

let subscribe_combat_events handler =
  subscribe_category [ Events.Event_bus.CombatEvent ] handler

(* Example: Movement event handler using effects *)
let handle_movement_events () =
  subscribe_movement_events (function
    | Events.Event_bus.EntityMoved { entity_id; from_pos; to_pos } ->
        log_info
          (Printf.sprintf "Entity %d moved from (%d,%d) to (%d,%d)" entity_id
             from_pos.world_pos.x from_pos.world_pos.y to_pos.world_pos.x
             to_pos.world_pos.y)
    | Events.Event_bus.EntityWantsToMove { entity_id; dir } ->
        log_info
          (Printf.sprintf "Entity %d wants to move %s" entity_id
             (Direction.show dir))
    | _ -> ())

(* Example: Combat event handler using effects *)
let handle_combat_events () =
  subscribe_combat_events (function
    | Events.Event_bus.EntityAttacked { attacker_id; defender_id } ->
        log_info
          (Printf.sprintf "Entity %d attacked entity %d" attacker_id defender_id)
    | Events.Event_bus.ActorDamaged { actor_id; amount } ->
        log_info (Printf.sprintf "Actor %d took %d damage" actor_id amount)
    | Events.Event_bus.EntityDied { entity_id } ->
        log_info (Printf.sprintf "Entity %d died" entity_id)
    | _ -> ())

(* Initialize all event handlers *)
let init () =
  with_event_system (fun () ->
      handle_movement_events ();
      handle_combat_events ();

      (* Example of a custom event handler that updates state *)
      subscribe (function
        | Events.Event_bus.EntityDied { entity_id } ->
            log_info (Printf.sprintf "Custom handler: Entity %d died" entity_id);

            (* We can use other effects inside event handlers *)
            log_info "Removing entity from state"
        | _ -> ()))
