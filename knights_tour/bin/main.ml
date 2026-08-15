(* Animation stays within the sizes where the search answers promptly. *)
let max_n = 20

let animate n =
  match Knights_tour.closed_tour n with
  | None ->
    Printf.printf "no closed tour exists for n = %d (odd boards and n < 6 have none)\n" n
  | Some tour -> Render.animate ~n tour
;;

(* Same exhaustive search, two candidate orders: fixed (naive) versus
   smallest-onward-count-first (Warnsdorff). The 6x6 board is the largest
   the naive order can handle. *)
let compare_orders () =
  Printf.printf "closed tour search on 6x6 (the naive order takes about a minute)\n%!";
  let measure label search =
    let t = Timeit.time (fun () -> ignore (search ())) in
    Printf.printf "  %-11s %8.3f s\n%!" label t;
    t
  in
  let tw = measure "warnsdorff" (fun () -> Knights_tour.closed_tour 6) in
  let tn = measure "naive" (fun () -> Knights_tour.closed_tour ~warnsdorff:false 6) in
  Printf.printf "  ordering alone buys a %.0fx speedup\n" (tn /. tw)
;;

let () =
  match Sys.argv with
  | [| _; "-c" |] -> compare_orders ()
  | [| _; arg |] ->
    (match int_of_string_opt arg with
     | Some n when n >= 1 && n <= max_n -> animate n
     | Some _ | None ->
       Printf.eprintf "error: expected a board size in [1, %d], got %S\n" max_n arg;
       exit 1)
  | _ ->
    Printf.eprintf
      "usage: %s <n>   animate a closed tour on the n x n board\n\
      \       %s -c   time naive vs warnsdorff ordering on 6x6\n"
      Sys.argv.(0)
      Sys.argv.(0);
    exit 1
;;
