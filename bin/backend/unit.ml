module Core = struct
  type properties = {
    mass : float;
    radius : float;
    max_eng : float;
    basedmg : float;
    courage : float;
    athletic : float;
    reaction : float;
    magic_aff : float;
  }

  type gender = Male | Female

  type t = {
    hp : float;
    eng : float;
    prop : properties;
    gender : gender option;
    controller : int option;
  }
end

(* Unit ID *)
type id = int
