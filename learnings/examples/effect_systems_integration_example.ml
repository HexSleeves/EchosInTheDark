(* effect_systems_integration_example.ml
   This module demonstrates how to integrate the effect event system
   with the other effect systems.
*)

open Base
open Types

(* Import the effect systems integration *)
module Effect_systems = Effect_systems.Effect_systems_integration
module Event_effects = Effect_systems.Event_effects
module Action_effects = Effect_systems.Action_effects
module Turn_effects = Effect_systems.Turn_effects

(* Example: Function that demonstrates how to use all effect systems together *)
let run_game_with_effects (state : State.t) : State.t =
  (* Use the effect systems integration to run the game with all effect handlers *)
  Effect_systems.run_with_all_handlers state (fun () ->
      (* Subscribe to movement events *)
      Event_effects.subscribe_movement_events (function
        | Events.Event_bus.EntityMoved { entity_id; from_pos; to_pos } ->
            Core_log.info (fun m ->
                m "Entity %d moved from (%d,%d) to (%d,%d)" entity_id
                  from_pos.world_pos.x from_pos.world_pos.y to_pos.world_pos.x
                  to_pos.world_pos.y)
        | _ -> ());

      (* Subscribe to combat events *)
      Event_effects.subscribe_combat_events (function
        | Events.Event_bus.EntityAttacked { attacker_id; defender_id } ->
            Core_log.info (fun m ->
                m "Entity %d attacked entity %d" attacker_id defender_id)
        | _ -> ());

      (* Process turns using the turn system integration *)
      Turn_effects.process_turns_hybrid state)

(* Example: Function that demonstrates how to perform an action and publish an event *)
let perform_action_and_publish_event (state : State.t) (entity_id : int)
    (action : Action.t) : State.t =
  Effect_systems.run_with_all_handlers state (fun () ->
      (* Perform the action *)
      match Action_effects.perform_action entity_id action with
      | Ok time_cost ->
          Core_log.info (fun m ->
              m "Action performed with time cost %d" time_cost);

          (* Schedule the entity for its next turn *)
          Turn_effects.schedule_actor entity_id time_cost;

          (* Publish an event *)
          Event_effects.publish_event
            (Events.Event_bus.EntityAttacked
               { attacker_id = entity_id; defender_id = 2 })
      | Error exn ->
          Core_log.err (fun m -> m "Action failed: %s" (Exn.to_string exn)))

(* Example: Function that demonstrates how to use the effect systems in the game loop *)
let game_loop (state : State.t) : State.t =
  (* Process turns with all effect handlers *)
  let state = run_game_with_effects state in

  (* Perform an action and publish an event *)
  let player_id = State.get_player_id state in
  let state =
    perform_action_and_publish_event state player_id
      (Action.Move Direction.North)
  in

  (* Return the updated state *)
  state
