# Effect System Integrations

This directory contains modules that provide integration between the existing game systems and the effect-based approach. These modules serve as bridges that allow gradual adoption of effect handlers without disrupting the existing codebase.

## Effect Event System Integration

The `effect_event_system_integration.ml` module provides integration between the existing event system and the effect-based approach. It allows you to:

- Publish events using effects
- Subscribe to events using effects
- Subscribe to specific event categories using effects

### How to Use

#### Publishing Events

```ocaml
open Effect_integrations.Effect_event_system_integration

(* Publish an event *)
let publish_player_spawn player_id pos =
  publish_event (Events.Event_bus.SpawnPlayer { player_id; pos })
```

#### Subscribing to Events

```ocaml
open Effect_integrations.Effect_event_system_integration

(* Subscribe to all events *)
let handle_all_events () =
  subscribe (function
    | Events.Event_bus.EntityDied { entity_id } ->
        Core_log.info (fun m -> m "Entity %d died" entity_id)
    | _ -> ())

(* Subscribe to specific event categories *)
let handle_movement_events () =
  subscribe_movement_events (function
    | Events.Event_bus.EntityMoved { entity_id; from_pos; to_pos } ->
        Core_log.info (fun m ->
            m "Entity %d moved from (%d,%d) to (%d,%d)" entity_id
              from_pos.world_pos.x from_pos.world_pos.y to_pos.world_pos.x
              to_pos.world_pos.y)
    | _ -> ())
```

#### Running with Event Handlers

```ocaml
open Effect_integrations.Effect_event_system_integration

(* Run a function with event handlers and return the updated state *)
let my_function state =
  run_with_events state (fun () ->
      (* Initialize event handlers *)
      handle_all_events ();
      handle_movement_events ();

      (* Publish events *)
      publish_event (Events.Event_bus.EntityDied { entity_id = 1 }))
```

## Integration with Other Effect Systems

The `effect_systems_integration.ml` module provides a unified interface for all game systems using effect handlers. It composes the individual effect handler modules to create a layered approach where each system focuses on its specific domain.

### How to Use

```ocaml
open Effect_integrations.Effect_systems_integration

(* Run a function with all system handlers and return the updated state *)
let my_function state =
  run_with_all_handlers state (fun () ->
      (* Your code here *)
      ())

(* Process turns using the layered effect handler approach *)
let process_turns state =
  run_with_all_handlers state (fun () ->
      Turn.process_turns_hybrid state)
```

## Examples

See the `src/core/examples` directory for examples of how to use the effect system integrations.
