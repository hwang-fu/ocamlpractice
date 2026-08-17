(* the sequences the CLI can print, by name *)
let sequences =
  [ "nats", Streams.nats
  ; "fibs", Streams.fibs
  ; "primes", Streams.primes
  ; "hamming", Streams.hamming
  ]
;;

let names = String.concat ", " (List.map fst sequences)

let () =
  match Sys.argv with
  | [| _; name; count |] ->
    (match List.assoc_opt name sequences, int_of_string_opt count with
     | Some stream, Some n when n >= 0 ->
       List.iter (Printf.printf "%d ") (Streams.take n stream);
       print_newline ()
     | None, _ ->
       Printf.eprintf "error: unknown sequence %S (known: %s)\n" name names;
       exit 1
     | Some _, _ ->
       Printf.eprintf "error: expected a nonnegative count, got %S\n" count;
       exit 1)
  | _ ->
    Printf.eprintf "usage: %s <sequence> <count>   (sequences: %s)\n" Sys.argv.(0) names;
    exit 1
;;
