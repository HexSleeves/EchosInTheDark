open Base

let default_seed = 0x7FFF
let default_state = Random.State.make_self_init ()
let generate_seed () = Random.State.int default_state default_seed
