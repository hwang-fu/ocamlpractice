let easy_puzzle =
  "003020600900305001001806400008102900700000008006708200002609500800203009005010300"
;;

let medium_puzzle =
  "200080300060070084030500209000105408000000000402706000301007040720040060004010003"
;;

let hard_puzzle =
  "4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"
;;

let builtin = function
  | "easy" -> Some easy_puzzle
  | "medium" -> Some medium_puzzle
  | "hard" -> Some hard_puzzle
  | _ -> None
;;

(* console rendering of a grid, with box separators *)
let pretty grid =
  let b = Buffer.create 256 in
  Array.iteri
    (fun c d ->
       Buffer.add_char b (if d = 0 then '.' else Char.chr (d + Char.code '0'));
       if c mod 9 = 8
       then (
         Buffer.add_char b '\n';
         if c mod 27 = 26 && c < 80 then Buffer.add_string b "------+-------+------\n")
       else (
         Buffer.add_char b ' ';
         if c mod 3 = 2 then Buffer.add_string b "| "))
    grid;
  Buffer.contents b
;;

let parse_or_exit s =
  match Sudoku.parse s with
  | Ok grid -> grid
  | Error e ->
    Printf.eprintf "error: %s\n" e;
    exit 1
;;

let animate s =
  let trace, result = Sudoku.solve (parse_or_exit s) in
  if result = None then print_endline "this puzzle has no solution; the replay shows why";
  Render.run trace
;;

let quiet s =
  match Sudoku.solve (parse_or_exit s) with
  | _, Some solution -> print_string (pretty solution)
  | _, None ->
    print_endline "no solution";
    exit 1
;;

let () =
  match Sys.argv with
  | [| _ |] -> animate hard_puzzle
  | [| _; "-q"; s |] -> quiet s
  | [| _; "-b"; name |] ->
    (match builtin name with
     | Some s -> animate s
     | None ->
       Printf.eprintf "error: unknown builtin %S (easy, medium or hard)\n" name;
       exit 1)
  | [| _; s |] -> animate s
  | _ ->
    Printf.eprintf
      "usage: %s [puzzle]        tutor-animate a puzzle (default: built-in hard)\n\
      \       %s -b <name>      built-ins: easy, medium, hard\n\
      \       %s -q <puzzle>    solve to the console, no window\n"
      Sys.argv.(0)
      Sys.argv.(0)
      Sys.argv.(0);
    exit 1
;;
