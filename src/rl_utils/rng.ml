open Base

let seed = 0x7FFF
let state = Random.State.make_self_init ()
let generate_seed () = Random.State.int state seed

let random_choice lst ~rng =
  List.nth lst (Random.State.int rng (List.length lst))
