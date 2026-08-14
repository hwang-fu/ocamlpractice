open Graphics

let width = 900
let height = 1200
let default_a = 300.

(* The cardioid spans x in [-1.3a, 1.3a] and y in [-2a, 0.25a] (widths 2.6a
   and 2.25a), which bounds the radius that fits in the window. *)
let max_a = Float.min (float width /. 2.6) (float height /. 2.25)
let steps = 200

(* Pause between segments, in seconds: the full curve takes steps * delay. *)
let delay = 0.01

let run a =
  open_graph (Printf.sprintf " %dx%d" width height);
  set_window_title "Cardioid";
  let center_x = width / 2 in
  (* centering the y-span [-2a, 0.25a] puts the origin at height/2 + 7a/8 *)
  let center_y = truncate ((float height /. 2.) +. (0.875 *. a)) in
  let to_pixel (x, y) = center_x + truncate x, center_y + truncate y in
  (* axes through the cardioid's origin, drawn before the animation starts;
     the ends stop short of the border so arrowheads and labels stay visible *)
  set_color (rgb 110 110 110);
  let x_tip = width - 30
  and y_tip = height - 30 in
  moveto 0 center_y;
  lineto x_tip center_y;
  lineto (x_tip - 12) (center_y + 6);
  moveto x_tip center_y;
  lineto (x_tip - 12) (center_y - 6);
  moveto (x_tip + 8) (center_y - 7);
  draw_string "x";
  moveto center_x 0;
  lineto center_x y_tip;
  lineto (center_x - 6) (y_tip - 12);
  moveto center_x y_tip;
  lineto (center_x + 6) (y_tip - 12);
  moveto (center_x + 12) (y_tip - 10);
  draw_string "y";
  set_color black;
  let x0, y0 = to_pixel (Cardioid.point a 0.) in
  moveto x0 y0;
  for i = 1 to steps do
    let theta = 2. *. Float.pi *. float i /. float steps in
    let x, y = to_pixel (Cardioid.point a theta) in
    lineto x y;
    (* X11 buffers drawing commands; synchronize flushes so each segment
       becomes visible before we sleep. *)
    synchronize ();
    Unix.sleepf delay
  done;
  try ignore (read_key ()) with
  | Graphic_failure _ -> ()
;;

let () =
  match Sys.argv with
  | [| _ |] -> run default_a
  | [| _; arg |] ->
    (match float_of_string_opt arg with
     | Some a when a > 0. && a <= max_a -> run a
     | Some _ | None ->
       Printf.eprintf "error: expected a radius in (0, %g], got %S\n" max_a arg;
       exit 1)
  | _ ->
    Printf.eprintf "usage: %s [radius]\n" Sys.argv.(0);
    exit 1
;;
