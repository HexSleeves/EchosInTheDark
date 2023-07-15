open Rl2023.Engine
open Components

let remove_entity id =
  let comps : (module Component.Sig) array =
    [|
      (module Position);
      (module Multiposition);
      (module Sprite);
      (module Text);
      (module Script);
      (module Input);
      (module Health);
      (module Enemy);
    |]
  in

  Array.iter
    (fun system ->
      let module CurrComp = (val system : Component.Sig) in
      CurrComp.remove id)
    comps

let can_die key = if Health.get key = 0 then remove_entity key
