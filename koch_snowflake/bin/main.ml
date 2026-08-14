open Graphics

let draw_polyline = function
  | [] -> ()
  | (x, y) :: rest ->
    moveto (truncate x) (truncate y);
    List.iter (fun (x, y) -> lineto (truncate x) (truncate y)) rest
;;

let run_with_depth d =
  open_graph (Printf.sprintf " %dx%d" Render.window_width Render.window_height);
  set_window_title "Koch snowflake";
  let cx = float Render.window_width /. 2.
  and cy = float Render.window_height /. 2. in
  let r = Render.radius_ratio *. float (min Render.window_width Render.window_height) in
  let vertex k =
    (* vertices at 90, -30, 210 degrees: a clockwise traversal, so the
       curve's leftward bumps point outward *)
    let angle = (Float.pi /. 2.) -. (2. *. Float.pi *. float k /. 3.) in
    cx +. (r *. cos angle), cy +. (r *. sin angle)
  in
  set_line_width Render.line_width;
  for k = 0 to 2 do
    draw_polyline (Koch_snowflake.koch d (vertex k) (vertex ((k + 1) mod 3)))
  done;
  try ignore (read_key ()) with
  | Graphic_failure _ -> ()
;;

let run_with_default_depth () = run_with_depth Render.default_depth

let () =
  match Sys.argv with
  | [| _ |] -> run_with_default_depth ()
  | [| _; arg |] ->
    (match int_of_string_opt arg with
     | Some d when Render.min_depth <= d && d <= Render.max_depth -> run_with_depth d
     | Some _ | None ->
       Printf.eprintf
         "error: expected a depth in [%d, %d], got %S\n"
         Render.min_depth
         Render.max_depth
         arg;
       exit 1)
  | _ ->
    Printf.eprintf "usage: %s [depth]\n" Sys.argv.(0);
    exit 1
;;
