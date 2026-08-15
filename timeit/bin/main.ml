(* Time summation loops of growing size: each measurement should be roughly
   ten times the previous one, illustrating measure-and-extrapolate. *)

let sum n =
  let s = ref 0 in
  for i = 1 to n do
    s := !s + i
  done;
  (* keep the result observable so the loop cannot be optimized away *)
  ignore (Sys.opaque_identity !s)
;;

let () =
  List.iter
    (fun n ->
       let t = Timeit.time (fun () -> sum n) in
       Printf.printf "sum of 1..%-13d %6.3f s\n%!" n t)
    [ 10_000_000; 100_000_000; 1_000_000_000 ]
;;
