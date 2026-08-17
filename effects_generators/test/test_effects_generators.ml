let () =
  (* a plain imperative loop, consumed as a sequence *)
  let squares =
    Effects_generators.to_seq (fun yield ->
      for i = 1 to 5 do
        yield (i * i)
      done)
  in
  assert (List.of_seq squares = [ 1; 4; 9; 16; 25 ]);
  (* laziness: the producer runs exactly as far as the consumer pulls *)
  let ran = ref 0 in
  let s =
    Effects_generators.to_seq (fun yield ->
      for i = 1 to 100 do
        incr ran;
        yield i
      done)
  in
  (match s () with
   | Seq.Nil -> assert false
   | Seq.Cons (x, _) -> assert (x = 1));
  assert (!ran = 1);
  (* same fringe across different shapes *)
  let open Effects_generators in
  let left_leaning = Node (Node (Leaf 1, Leaf 2), Leaf 3) in
  let right_leaning = Node (Leaf 1, Node (Leaf 2, Leaf 3)) in
  assert (List.of_seq (fringe left_leaning) = [ 1; 2; 3 ]);
  assert (same_fringe left_leaning right_leaning);
  (* different values, and different lengths *)
  assert (not (same_fringe (Leaf 1) (Leaf 2)));
  assert (not (same_fringe (Node (Leaf 1, Leaf 2)) (Leaf 1)));
  (* lockstep early exit: comparison stops at the first difference *)
  let pulls = ref 0 in
  let counted xs =
    to_seq (fun yield ->
      List.iter
        (fun x ->
           incr pulls;
           yield x)
        xs)
  in
  assert (not (Seq.equal ( = ) (counted [ 1; 9; 3; 4; 5 ]) (counted [ 1; 2; 3; 4; 5 ])));
  assert (!pulls = 4);
  (* walking again from the head restarts the producer: same elements,
     side effects run twice *)
  let runs = ref 0 in
  let restartable =
    to_seq (fun yield ->
      incr runs;
      yield 1;
      yield 2)
  in
  assert (List.of_seq restartable = [ 1; 2 ]);
  assert (List.of_seq restartable = [ 1; 2 ]);
  assert (!runs = 2);
  (* pulling the same node twice resumes a one-shot continuation twice *)
  (match to_seq (fun yield -> yield 1) () with
   | Seq.Nil -> assert false
   | Seq.Cons (_, tail) ->
     ignore (tail ());
     (match tail () with
      | _ -> assert false
      | exception Effect.Continuation_already_resumed -> ()));
  (* memoize removes both hazards: two walks, producer runs once *)
  let memo_runs = ref 0 in
  let memoized =
    Seq.memoize
      (to_seq (fun yield ->
         incr memo_runs;
         yield 1;
         yield 2))
  in
  assert (List.of_seq memoized = [ 1; 2 ]);
  assert (List.of_seq memoized = [ 1; 2 ]);
  assert (!memo_runs = 1);
  print_endline "all tests passed"
;;
