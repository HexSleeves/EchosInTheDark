open Base
open Components
open Events.Event_bus

let () =
  subscribe (function
    | EntityAttacked { attacker_id = _; defender_id; damage } -> (
        match Stats.get defender_id with
        | Some stats ->
            let new_hp = stats.hp - damage in
            publish (ActorDamaged { actor_id = defender_id; amount = damage });
            if new_hp <= 0 then publish (EntityDied { entity_id = defender_id });
            (* TODO: Actually update the stats in the component table *)
            ()
        | None -> ())
    | _ -> ())
