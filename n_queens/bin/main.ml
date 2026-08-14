let () =
  match Sys.argv with
  | [| _; arg |] ->
    (match int_of_string_opt arg with
     | Some n when n >= 0 -> Printf.printf "%d\n" (N_queens.count n)
     | Some _ | None ->
       Printf.eprintf "error: expected a nonnegative integer, got %S\n" arg;
       exit 1)
  | _ ->
    Printf.eprintf "usage: %s <n>\n" Sys.argv.(0);
    exit 1
;;
