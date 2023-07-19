open Stdlib

let load_from_file file =
  let ic = open_in_bin file in
  let s = input_value ic in
  close_in ic;
  s

let save_to_file s file =
  let oc = open_out_bin file in
  output_value oc s;
  flush oc;
  close_out oc
