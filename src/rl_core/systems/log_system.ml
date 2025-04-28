open Types
open Events.Event_bus

let () =
  subscribe (function
    | EntityMoved { entity_id; from_pos; to_pos } ->
        Stdio.printf "Entity %d moved from %s to %s\n" entity_id
          (Loc.show from_pos) (Loc.show to_pos)
    | ActorDamaged { actor_id; amount } ->
        Stdio.printf "Actor %d took %d damage\n" actor_id amount
    | TrapTriggered { entity_id; trap_id } ->
        Stdio.printf "Entity %d triggered trap %d\n" entity_id trap_id
    | EntityAttacked { attacker_id; defender_id } ->
        Stdio.printf "Entity %d attacked %d\n" attacker_id defender_id
    | EntityDied { entity_id } -> Stdio.printf "Entity %d died\n" entity_id)
