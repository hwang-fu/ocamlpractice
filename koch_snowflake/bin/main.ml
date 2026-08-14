let () =
  match Sys.argv with
  | [| _ |] -> Render.run_with_default_depth ()
  | [| _; arg |] ->
    (match int_of_string_opt arg with
     | Some d when Render.depth_in_range d -> Render.run_with_depth d
     | Some _ | None ->
       Printf.eprintf "error: expected a depth in %s, got %S\n" Render.depth_range arg;
       exit 1)
  | _ ->
    Printf.eprintf "usage: %s [depth]\n" Sys.argv.(0);
    exit 1
;;
