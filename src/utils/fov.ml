let in_bounds x y width height = x >= 0 && x < width && y >= 0 && y < height

let distance2 x0 y0 x1 y1 =
  let dx = x1 - x0 in
  let dy = y1 - y0 in
  (dx * dx) + (dy * dy)

let rec cast_light ~is_opaque ~width ~height ~origin_x ~origin_y ~radius ~xx ~xy
    ~yx ~yy row start_slope end_slope visible =
  if start_slope < end_slope then ()
  else
    let radius2 = radius * radius in
    let blocked = ref false in
    let mutable_col = ref row in
    let new_start_slope = ref start_slope in
    while !mutable_col <= radius do
      let dx = !mutable_col in
      let dy = -row in
      let mx = origin_x + (dx * xx) + (dy * xy) in
      let my = origin_y + (dx * yx) + (dy * yy) in
      let l_slope = float_of_int (dx - 1) /. float_of_int (row + 1) in
      let r_slope = float_of_int (dx + 1) /. float_of_int (row - 1) in
      if
        in_bounds mx my width height
        && distance2 origin_x origin_y mx my <= radius2
      then visible := (mx, my) :: !visible;
      if !blocked then
        if is_opaque mx my then ()
        else (
          blocked := false;
          new_start_slope := l_slope)
      else if is_opaque mx my && !mutable_col < radius then (
        blocked := true;
        cast_light ~is_opaque ~width ~height ~origin_x ~origin_y ~radius ~xx ~xy
          ~yx ~yy (row + 1) !new_start_slope r_slope visible);
      incr mutable_col
    done

let compute_fov ~is_opaque ~width ~height ~origin ~radius =
  let ox, oy = origin in
  let visible = ref [ (ox, oy) ] in
  let transforms =
    [|
      (1, 0, 0, 1);
      (* E *)
      (0, 1, 1, 0);
      (* N *)
      (-1, 0, 0, 1);
      (* W *)
      (0, -1, 1, 0);
      (* S *)
      (1, 0, 0, -1);
      (* SE *)
      (0, 1, -1, 0);
      (* NE *)
      (-1, 0, 0, -1);
      (* SW *)
      (0, -1, -1, 0);
      (* NW *)
    |]
  in
  for oct = 0 to 7 do
    let xx, xy, yx, yy = transforms.(oct) in
    cast_light ~is_opaque ~width ~height ~origin_x:ox ~origin_y:oy ~radius ~xx
      ~xy ~yx ~yy 1 1.0 0.0 visible
  done;
  !visible
