let () =
  match Sys.argv with
  | [| _ |] -> Render.run ()
  | [| _; arg |] ->
    (match int_of_string_opt arg with
     | Some d when Render.depth_in_range d -> Render.run ~depth:d ()
     | Some _ | None -> Render.exit_invalid_depth arg)
  | _ ->
    Printf.eprintf "usage: %s [depth]\n" Sys.argv.(0);
    exit 1
;;
