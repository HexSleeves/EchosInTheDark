let chunk_w = 50
let chunk_h = 32
let world_w = 214
let world_h = 128
let chunk_load_radius = 2
let chunk_file_name cx cy = Printf.sprintf "chunk_%d_%d.json" cx cy
let chunk_dir = "resources/chunks"
let chunk_dir_path depth = Printf.sprintf "%s/%d" chunk_dir depth

let chunk_path cx cy depth =
  Printf.sprintf "%s/%s" (chunk_dir_path depth) (chunk_file_name cx cy)

let chunk_entity_path cx cy depth =
  Printf.sprintf "resources/chunks/%d/chunk_%d_%d_entities.json" depth cx cy
