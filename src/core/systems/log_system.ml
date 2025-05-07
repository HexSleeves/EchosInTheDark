open Events.Event_bus
open Components

let init () =
  subscribe (function
    | EntityMoved { entity_id; from_pos; to_pos } ->
        fun state ->
          Stdio.printf "Entity %d moved from %s to %s\n" entity_id
            (Position.show from_pos) (Position.show to_pos);
          state
    | ActorDamaged { actor_id; amount } ->
        fun state ->
          Stdio.printf "Actor %d took %d damage\n" actor_id amount;
          state
    | TrapTriggered { entity_id; trap_id } ->
        fun state ->
          Stdio.printf "Entity %d triggered trap %d\n" entity_id trap_id;
          state
    | EntityAttacked { attacker_id; defender_id } ->
        fun state ->
          Stdio.printf "Entity %d attacked %d\n" attacker_id defender_id;
          state
    | EntityDied { entity_id } ->
        fun state ->
          Stdio.printf "Entity %d died\n" entity_id;
          state
    | _ -> fun state -> state)
