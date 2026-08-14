let () =
  match Sys.argv with
  | [| _; arg |] ->
    (match int_of_string_opt arg with
     | Some year ->
       let msg = if Leap.is_leap year then "is" else "is not" in
       Printf.printf "%d %s a leap year\n" year msg
     | None ->
       Printf.eprintf "error: %S is not an integer\n" arg;
       exit 1)
  | _ ->
    Printf.eprintf "usage: %s <year>\n" Sys.argv.(0);
    exit 1
;;
