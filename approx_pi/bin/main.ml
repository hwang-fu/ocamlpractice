open Graphics

let size = 500

let run n =
  Random.self_init ();
  open_graph (Printf.sprintf " %dx%d" size size);
  set_window_title "Monte-Carlo approximation of pi";
  draw_arc 0 0 size size 0 90;
  let draw_point x y inside =
    set_color (if inside then red else blue);
    plot (int_of_float (x *. float size)) (int_of_float (y *. float size))
  in
  let pi = Approx_pi.approx_pi ~plot:draw_point n in
  Printf.printf "%f\n%!" pi;
  (* Closing the window via the window manager kills the Graphics connection,
     making [read_key] raise instead of returning. *)
  try ignore (read_key ()) with
  | Graphic_failure _ -> ()
;;

let () =
  match Sys.argv with
  | [| _; arg |] ->
    (match int_of_string_opt arg with
     | Some n when n > 0 -> run n
     | Some _ | None ->
       Printf.eprintf "error: expected a positive integer, got %S\n" arg;
       exit 1)
  | _ ->
    Printf.eprintf "usage: %s <number-of-points>\n" Sys.argv.(0);
    exit 1
;;
