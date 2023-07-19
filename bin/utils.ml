(** [fold_lim f x xl] is a function that folds over a range of values from x to xl using the function f and an accumulator a. *)
let rec fold_lim f a x xl = if x <= xl then fold_lim f (f a x) (x + 1) xl else a
