open Base
open Rl_types

(* Define core event types here. Expand as needed. *)
type event =
  | SpawnPlayer of { player_id : int; pos : Components.Position.t }
  | SpawnCreature of { creature_id : int; pos : Components.Position.t }
  | SpawnItem of { item_id : int; pos : Components.Position.t }
  | ActorDamaged of { actor_id : int; amount : int }
  | TrapTriggered of { entity_id : int; trap_id : int }
  | EntityAttacked of { attacker_id : int; defender_id : int }
  | EntityDied of { entity_id : int }
  | ItemPickedUp of { player_id : int; item_id : int }
  | ItemDropped of { player_id : int; item_id : int }
  | EntityWantsToMove of { entity_id : int; dir : Direction.t }
  | EntityMoved of {
      entity_id : int;
      from_pos : Components.Position.t;
      to_pos : Components.Position.t;
    }
  | StairsUp of { entity_id : int }
  | StairsDown of { entity_id : int }

(* Add more events as needed *)

type t = event

(* Define the event categories internally for optimized dispatch *)
type event_category =
  | PlayerEvent
  | CreatureEvent
  | ItemEvent
  | MovementEvent
  | StairsEvent
  | CombatEvent
  | AnyEvent (* Generic category for all events *)
[@@deriving eq, show]

(* Map events to their categories *)
let categorize_event = function
  | SpawnPlayer _ -> [ PlayerEvent ]
  | SpawnCreature _ -> [ CreatureEvent ]
  | SpawnItem _ | ItemPickedUp _ | ItemDropped _ -> [ ItemEvent ]
  | EntityWantsToMove _ | EntityMoved _ -> [ MovementEvent ]
  | StairsUp _ | StairsDown _ -> [ StairsEvent ]
  | ActorDamaged _ | EntityAttacked _ | EntityDied _ | TrapTriggered _ ->
      [ CombatEvent ]

(* Handler type: takes an event and returns unit *)
type handler = event -> State_types.t -> State_types.t

(* Internal structure to store handlers with metadata *)
type handler_entry = {
  id : string;
  fn : handler;
  categories : event_category list option; (* None means all categories *)
}

(* Internal list of handlers *)
let handlers : handler_entry list ref = ref []

(* Add a handler with optional category filtering *)
let add_handler ?(id = "") ?(categories = None) (fn : handler) =
  let entry = { id; categories; fn } in
  handlers := entry :: !handlers

(* Get relevant handlers for an event *)
let get_handlers_for_event (ev : event) : handler list =
  let ev_categories = categorize_event ev in

  !handlers
  |> List.filter ~f:(fun entry ->
         match entry.categories with
         | None -> true (* Handler wants all events *)
         | Some cats ->
             (* Check if any of the handler's categories match the event's categories *)
             List.exists cats ~f:(fun cat ->
                 List.exists ev_categories ~f:(fun ev_cat ->
                     equal_event_category cat ev_cat)))
  |> List.map ~f:(fun entry -> entry.fn)

(* Publish function - same API as before, but optimized implementation *)
let publish (ev : event) (state : State_types.t) : State_types.t =
  let relevant_handlers = get_handlers_for_event ev in
  List.fold_left relevant_handlers ~init:state ~f:(fun st h -> h ev st)

(* Standard subscribe function - same API as before *)
let subscribe (f : handler) : unit = add_handler ~categories:None f

(* Subscribe to specific event categories *)
let subscribe_category ?(id = "") (categories : event_category list)
    (f : handler) : unit =
  add_handler ~id ~categories:(Some categories) f

(* Subscribe to item events *)
let subscribe_item_events ?(id = "") (f : handler) : unit =
  subscribe_category ~id [ ItemEvent ] f

(* Subscribe to movement events *)
let subscribe_movement_events ?(id = "") (f : handler) : unit =
  subscribe_category ~id [ MovementEvent ] f

(* Subscribe to combat events *)
let subscribe_combat_events ?(id = "") (f : handler) : unit =
  subscribe_category ~id [ CombatEvent ] f

(* Subscribe to player events *)
let subscribe_player_events ?(id = "") (f : handler) : unit =
  subscribe_category ~id [ PlayerEvent ] f

(* Subscribe to creature events *)
let subscribe_creature_events ?(id = "") (f : handler) : unit =
  subscribe_category ~id [ CreatureEvent ] f

(* Subscribe to stairs events *)
let subscribe_stairs_events ?(id = "") (f : handler) : unit =
  subscribe_category ~id [ StairsEvent ] f
