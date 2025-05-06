open Base
open Components
open Events.Event_bus

let calculate_damage ~attacker_stats ~defender_stats =
  let open Components.Stats.Stats_data in
  let base_damage = attacker_stats.attack - defender_stats.defense in
  max 1 base_damage

let init () =
  subscribe (function
    | EntityAttacked { attacker_id; defender_id } -> (
        fun state ->
          match (Stats.get attacker_id, Stats.get defender_id) with
          | Some attacker_stats, Some defender_stats ->
              let damage = calculate_damage ~attacker_stats ~defender_stats in
              let new_hp = defender_stats.hp - damage in
              Stats.set defender_id { defender_stats with hp = new_hp };
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
              state
          | _ -> state)
    | EntityDied { entity_id } ->
        fun state -> State.remove_entity entity_id state
    | _ -> fun state -> state)
