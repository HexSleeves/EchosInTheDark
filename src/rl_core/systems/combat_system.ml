open Base
open Events.Event_bus

let packed_components = Packed_system.packed_components
let packed = !packed_components

let calculate_damage ~(attacker_stats : Packed_components.Stats.t)
    ~(defender_stats : Packed_components.Stats.t) =
  let base_damage = attacker_stats.attack - defender_stats.defense in
  max 1 base_damage

let init () =
  subscribe_combat_events (function
    | EntityAttacked { attacker_id; defender_id } -> (
        fun state ->
          (* Use packed system for stat access and update *)
          let open Packed_components in
          match
            (get_stats packed attacker_id, get_stats packed defender_id)
          with
          | ( Some (attacker_stats : Packed_components.Stats.t),
              Some (defender_stats : Packed_components.Stats.t) ) ->
              let damage = calculate_damage ~attacker_stats ~defender_stats in
              let new_hp = defender_stats.hp - damage in
              set_stats packed defender_id { defender_stats with hp = new_hp };

              let state =
                publish
                  (ActorDamaged { actor_id = defender_id; amount = damage })
                  state
              in
              let state =
                if new_hp <= 0 then
                  publish (EntityDied { entity_id = defender_id }) state
                else state
              in

              (* Sync packed system back to hashtables for consistency *)
              Packed_system.sync_to_hashtables ();
              state
          | _ -> state)
    | EntityDied { entity_id } ->
        fun state -> State.remove_entity entity_id state
    | _ -> fun state -> state)
