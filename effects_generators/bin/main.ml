(* Two small demos of the generator library. *)

let () =
  (* an imperative loop, consumed on demand as a sequence *)
  let squares =
    Effects_generators.to_seq (fun yield ->
      for i = 1 to 8 do
        yield (i * i)
      done)
  in
  print_string "squares:  ";
  Seq.iter (Printf.printf "%d ") squares;
  print_newline ();
  (* same-fringe: shapes differ, leaves may or may not *)
  let open Effects_generators in
  let t1 = Node (Node (Leaf 1, Leaf 2), Leaf 3) in
  let t2 = Node (Leaf 1, Node (Leaf 2, Leaf 3)) in
  let t3 = Node (Leaf 1, Node (Leaf 9, Leaf 3)) in
  Printf.printf "t1 ~ t2:  %b   (same leaves, different shapes)\n" (same_fringe t1 t2);
  Printf.printf "t1 ~ t3:  %b  (second leaf differs)\n" (same_fringe t1 t3)
;;
