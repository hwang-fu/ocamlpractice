let () =
  (* known prefixes of the showpiece sequences *)
  assert (Streams.take 10 Streams.nats = [ 0; 1; 2; 3; 4; 5; 6; 7; 8; 9 ]);
  assert (Streams.take 10 Streams.fibs = [ 0; 1; 1; 2; 3; 5; 8; 13; 21; 34 ]);
  assert (Streams.take 10 Streams.primes = [ 2; 3; 5; 7; 11; 13; 17; 19; 23; 29 ]);
  assert (Streams.take 10 Streams.hamming = [ 1; 2; 3; 4; 5; 6; 8; 9; 10; 12 ]);
  (* combinators *)
  assert (Streams.take 5 (Streams.map (fun x -> x * x) Streams.nats) = [ 0; 1; 4; 9; 16 ]);
  assert (
    Streams.take 4 (Streams.filter (fun x -> x mod 3 = 0) Streams.nats) = [ 0; 3; 6; 9 ]);
  assert (Streams.take 3 (Streams.zip_with ( + ) Streams.nats Streams.fibs) = [ 0; 2; 3 ]);
  (* take 0 does no work at all: a poisoned stream is harmless unforced *)
  let poisoned = Streams.Cons (1, lazy (failwith "boom")) in
  assert (Streams.head poisoned = 1);
  assert (Streams.take 1 (Streams.map succ poisoned) = [ 2 ]);
  (* memoization: traversing a stream twice runs its effects once... *)
  let calls = ref 0 in
  let counted =
    Streams.iterate
      (fun x ->
         incr calls;
         x + 1)
      0
  in
  ignore (Streams.take 5 counted);
  let after_first = !calls in
  ignore (Streams.take 5 counted);
  assert (!calls = after_first);
  (* ...where the stdlib's Seq, thunk-based, re-runs them per traversal *)
  let seq_calls = ref 0 in
  let seq_counted =
    Seq.ints 0
    |> Seq.map (fun x ->
      incr seq_calls;
      x + 1)
  in
  ignore (List.of_seq (Seq.take 5 seq_counted));
  let seq_after_first = !seq_calls in
  ignore (List.of_seq (Seq.take 5 seq_counted));
  assert (!seq_calls = 2 * seq_after_first);
  (* the Seq bridge: round trip through to_seq keeps the elements *)
  assert (List.of_seq (Seq.take 5 (Streams.to_seq Streams.primes)) = [ 2; 3; 5; 7; 11 ]);
  assert (Streams.take 5 (Streams.of_seq (Seq.ints 3)) = [ 3; 4; 5; 6; 7 ]);
  print_endline "all tests passed"
;;
