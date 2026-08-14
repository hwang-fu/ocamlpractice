(* Verify [solve n] by simulation: replay the moves on real stacks,
   asserting every move is legal, then check the final position. *)
let () =
  List.iter
    (fun n ->
       let moves = Hanoi.solve n in
       (* 2^n - 1 moves *)
       assert (List.length moves = (1 lsl n) - 1);
       let pegs = [| List.init n (fun i -> i + 1); []; [] |] in
       List.iter
         (fun (src, dst) ->
            match pegs.(src) with
            | [] -> assert false
            | d :: rest ->
              (match pegs.(dst) with
               | [] -> ()
               | d' :: _ -> assert (d < d'));
              pegs.(src) <- rest;
              pegs.(dst) <- d :: pegs.(dst))
         moves;
       assert (pegs.(0) = []);
       assert (pegs.(1) = []);
       assert (pegs.(2) = List.init n (fun i -> i + 1)))
    [ 0; 1; 2; 3; 5; 8; 10 ];
  print_endline "all tests passed"
;;
