open Graphics

let width = 600
let height = 800

(* The cardioid spans x in [-1.3a, 1.3a] and y in [-2a, 0.25a]; with a = 200
   that is 520 x 450 pixels, and placing the origin (the cusp) at
   (300, 575) centers the curve in the 600 x 800 window. *)
let a = 200.
let center_x = width / 2
let center_y = 575
let steps = 200
let to_pixel (x, y) = center_x + truncate x, center_y + truncate y

let () =
  open_graph (Printf.sprintf " %dx%d" width height);
  set_window_title "Cardioid";
  let x0, y0 = to_pixel (Cardioid.point a 0.) in
  moveto x0 y0;
  for i = 1 to steps do
    let theta = 2. *. Float.pi *. float i /. float steps in
    let x, y = to_pixel (Cardioid.point a theta) in
    lineto x y
  done;
  try ignore (read_key ()) with
  | Graphic_failure _ -> ()
;;
