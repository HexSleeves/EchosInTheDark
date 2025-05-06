(* effect_event_system_example.ml
   This module demonstrates how to use the effect event system integration
   in a real game scenario.
*)

open Base
open Events.Event_bus

(* Import the effect systems integration *)
module Effect_systems = Effect_systems.Effect_systems_integration
module Event_effects = Effect_systems.Event_effects

(* Example: Custom event handler for player movement *)
let handle_player_movement () =
  Event_effects.subscribe_movement_events (function
    | EntityMoved { entity_id; from_pos; to_pos } -> (
        (* Check if this is the player *)
        match Components.Kind.get entity_id with
        | Some Components.Kind.Player ->
            Core_log.info (fun m ->
                m "Player moved from (%d,%d) to (%d,%d)" from_pos.world_pos.x
                  from_pos.world_pos.y to_pos.world_pos.x to_pos.world_pos.y)
        | _ -> ())
    | _ -> ())

(* Example: Custom event handler for combat events *)
let handle_combat_events () =
  Event_effects.subscribe_combat_events (function
    | EntityAttacked { attacker_id; defender_id } ->
        Core_log.info (fun m ->
            m "Entity %d attacked entity %d" attacker_id defender_id)
    | ActorDamaged { actor_id; amount } ->
        Core_log.info (fun m -> m "Actor %d took %d damage" actor_id amount)
    | _ -> ())

(* Example: Custom event handler that modifies game state *)
let handle_entity_death () =
  Event_effects.subscribe (function
    | EntityDied { entity_id } ->
        Core_log.info (fun m -> m "Entity %d died, handling cleanup" entity_id);
        (* We could perform additional cleanup here *)
        ()
    | _ -> ())

(* Initialize all event handlers *)
let init () =
  handle_player_movement ();
  handle_combat_events ();
  handle_entity_death ()

(* Example: Function that uses the effect systems integration to process a turn *)
let process_turn (state : State.t) : State.t =
  (* Use the effect systems integration to process a turn *)
  Effect_systems.run_with_all_handlers state (fun () ->
      (* This will use all effect handlers, including our event handlers *)
      Core_log.info (fun m -> m "Processing turn with effect handlers");

      (* Example: Publish a movement event *)
      let player_id = State.get_player_id state in
      let player_pos = Components.Position.get_exn player_id in
      let new_pos =
        Components.Position.make
          { x = player_pos.world_pos.x + 1; y = player_pos.world_pos.y }
      in

      Event_effects.publish_event
        (EntityMoved
           { entity_id = player_id; from_pos = player_pos; to_pos = new_pos }))

(* Example: Function that demonstrates how to use the effect event system in the game loop *)
let game_loop (state : State.t) : State.t =
  (* Initialize our event handlers *)
  init ();

  (* Process a turn with our event handlers *)
  let state = process_turn state in

  (* Return the updated state *)
  state
