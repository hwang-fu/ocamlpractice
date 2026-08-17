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
  print_endline "all tests passed"
;;
