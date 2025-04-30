open Base

(** Map a species string to a default faction. Expand as needed. *)
let faction_of_species (species : Components.Species.t) : Components.Faction.t =
  match species with
  | `Rat | `Giant_Cave_Rat | `Bat | `Bloated_Bat | `Ore_Slime | `Copper_Slime
  | `Iron_Slime ->
      `Vermin
  | `Kobold | `Grumbling_Kobold -> `Kobold
  | `Goblin | `Goblin_Sapper -> `Goblin
  | `Rock_Golem -> `Elemental
  | `Giant_Spider -> `Vermin
  | `Shadow_Creeper -> `Abomination
  | `Undead_Miner -> `Undead
  | `Deep_Worm -> `Abomination
  | `Crystalline_Horror -> `Elemental
  | `Mind_Flayer | `Illithid -> `Abomination
  | `Elemental_Guardian -> `Elemental
  | `Mutated_Abomination -> `Abomination
  | `Glowbug | `Cave_Beetle -> `FriendlyBug
  | _ -> `Neutral

(** Determine if two factions are hostile to each other. *)
let are_factions_hostile (f1 : Components.Faction.t) (f2 : Components.Faction.t)
    : bool =
  match (f1, f2) with
  | `Player, `Player -> false
  | `Player, (`FriendlyBug | `Neutral) -> false
  | (`FriendlyBug | `Neutral), `Player -> false
  | `FriendlyBug, `FriendlyBug -> false
  | `Vermin, `Vermin -> false
  | `Kobold, `Kobold -> false
  | `Goblin, `Goblin -> false
  | `Elemental, `Elemental -> false
  | `Undead, `Undead -> false
  | `Abomination, `Abomination -> false
  | `Player, _ | _, `Player -> true
  | `Vermin, _ | _, `Vermin -> true
  | `Kobold, _ | _, `Kobold -> true
  | `Goblin, _ | _, `Goblin -> true
  | `Elemental, _ | _, `Elemental -> true
  | `Undead, _ | _, `Undead -> true
  | `Abomination, _ | _, `Abomination -> true
  | `FriendlyBug, _ | _, `FriendlyBug -> false
  | `Neutral, _ | _, `Neutral -> false
  | `Other a, `Other b -> String.equal a b

