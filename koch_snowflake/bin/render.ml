open Graphics

(* Rendering parameters: the window, the drawing style, and the depth
   budget. Depth is capped because segments grow as 4^depth: depth 8 already
   draws ~200k sub-pixel segments, deeper is pointless work. *)

let window_width = 1600
let window_height = 1600
let default_depth = 4
let min_depth = 0
let max_depth = 8

(* the snowflake stays inside the circumcircle of its base triangle, so this
   ratio of the window's smaller dimension fills it with a small margin *)
let radius_ratio = 0.45
let line_width = 2
let depth_in_range depth = min_depth <= depth && depth <= max_depth
let depth_range = Printf.sprintf "[%d, %d]" min_depth max_depth

let draw_polyline = function
  | [] -> ()
  | (x, y) :: rest ->
    moveto (truncate x) (truncate y);
    List.iter (fun (x, y) -> lineto (truncate x) (truncate y)) rest
;;

let run ?(depth = default_depth) () =
  open_graph (Printf.sprintf " %dx%d" window_width window_height);
  set_window_title "Koch snowflake";
  let cx = float window_width /. 2.
  and cy = float window_height /. 2. in
  let r = radius_ratio *. float (min window_width window_height) in
  let vertex k =
    (* vertices at 90, -30, 210 degrees: a clockwise traversal, so the
       curve's leftward bumps point outward *)
    let angle = (Float.pi /. 2.) -. (2. *. Float.pi *. float k /. 3.) in
    cx +. (r *. cos angle), cy +. (r *. sin angle)
  in
  set_line_width line_width;
  for k = 0 to 2 do
    draw_polyline (Koch_snowflake.koch depth (vertex k) (vertex ((k + 1) mod 3)))
  done;
  try ignore (read_key ()) with
  | Graphic_failure _ -> ()
;;
