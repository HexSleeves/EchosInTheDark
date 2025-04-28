open Base
open Components
open Events.Event_bus

let calculate_damage ~attacker_stats ~defender_stats =
  let open Types.Stats in
  let base_damage = attacker_stats.attack - defender_stats.defense in
  max 1 base_damage

let () =
  subscribe (function
    | EntityAttacked { attacker_id; defender_id } -> (
        match (Stats.get attacker_id, Stats.get defender_id) with
        | Some attacker_stats, Some defender_stats ->
            let open Types.Stats in
            let damage = calculate_damage ~attacker_stats ~defender_stats in
            let new_hp = defender_stats.hp - damage in
            Stats.set defender_id { defender_stats with hp = new_hp };
            publish (ActorDamaged { actor_id = defender_id; amount = damage });
            if new_hp <= 0 then publish (EntityDied { entity_id = defender_id });
            ()
        | _ -> ())
    | _ -> ())
