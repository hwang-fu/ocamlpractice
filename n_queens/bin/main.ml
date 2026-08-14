open Graphics

let win_w = 700
let win_h = 820
let board_px = 640

(* Interactive mode enumerates and stores every solution, so its board size
   is capped; count mode stays unrestricted. *)
let interactive_min = 1
let interactive_max = 10

type rect =
  { x : int
  ; y : int
  ; w : int
  ; h : int
  }

let prev_button = { x = 80; y = 40; w = 140; h = 50 }
let next_button = { x = 480; y = 40; w = 140; h = 50 }
let inside r mx my = mx >= r.x && mx <= r.x + r.w && my >= r.y && my <= r.y + r.h

let draw_button r label =
  set_color black;
  draw_rect r.x r.y r.w r.h;
  let tw, th = text_size label in
  moveto (r.x + ((r.w - tw) / 2)) (r.y + ((r.h - th) / 2));
  draw_string label
;;

let draw_board n queens =
  let cell = board_px / n in
  let x0 = (win_w - (cell * n)) / 2 in
  let y0 = 150 in
  for r = 0 to n - 1 do
    for c = 0 to n - 1 do
      set_color (if (r + c) mod 2 = 0 then white else black);
      fill_rect (x0 + (c * cell)) (y0 + (r * cell)) cell cell
    done
  done;
  (* border so the white edge squares stand out against the background *)
  set_color black;
  draw_rect x0 y0 (cell * n) (cell * n);
  set_color (rgb 190 30 30);
  (* row 0 is the top board row, while the Graphics y axis points up *)
  List.iteri
    (fun r c ->
       fill_circle
         (x0 + (c * cell) + (cell / 2))
         (y0 + ((n - 1 - r) * cell) + (cell / 2))
         (cell / 3))
    queens
;;

let draw_status n idx total =
  let label = Printf.sprintf "n = %d    solution %d / %d" n (idx + 1) total in
  let tw, _ = text_size label in
  set_color black;
  moveto ((win_w - tw) / 2) 105;
  draw_string label
;;

let draw_state n sols idx =
  clear_graph ();
  draw_board n sols.(idx);
  draw_status n idx (Array.length sols);
  draw_button prev_button "< Prev";
  draw_button next_button "Next >"
;;

(* The UI state -- which solution is displayed -- travels as the argument of
   a tail-recursive event loop, exactly like the search state in the lib. *)
let rec loop n sols idx =
  draw_state n sols idx;
  let e = wait_next_event [ Button_down; Key_pressed ] in
  let total = Array.length sols in
  let next = (idx + 1) mod total
  and prev = (idx + total - 1) mod total in
  if e.button
  then
    if inside prev_button e.mouse_x e.mouse_y
    then loop n sols prev
    else if inside next_button e.mouse_x e.mouse_y
    then loop n sols next
    else loop n sols idx
  else (
    match e.key with
    | 'n' -> loop n sols next
    | 'p' -> loop n sols prev
    | 'q' -> ()
    | _ -> loop n sols idx)
;;

let interactive n =
  match N_queens.solutions n with
  | [] -> Printf.printf "no solution for n = %d\n" n
  | sols ->
    let sols = Array.of_list sols in
    open_graph (Printf.sprintf " %dx%d" win_w win_h);
    set_window_title "N queens";
    (try loop n sols 0 with
     | Graphic_failure _ -> ())
;;

let count_mode n = Printf.printf "%d\n" (N_queens.count n)

let () =
  match Sys.argv with
  | [| _; arg |] ->
    (match int_of_string_opt arg with
     | Some n when n >= 0 -> count_mode n
     | Some _ | None ->
       Printf.eprintf "error: expected a nonnegative integer, got %S\n" arg;
       exit 1)
  | [| _; "-i"; arg |] ->
    (match int_of_string_opt arg with
     | Some n when interactive_min <= n && n <= interactive_max -> interactive n
     | Some _ | None ->
       Printf.eprintf
         "error: interactive mode expects an integer in [%d, %d], got %S\n"
         interactive_min
         interactive_max
         arg;
       exit 1)
  | _ ->
    Printf.eprintf "usage: %s [-i] <n>\n" Sys.argv.(0);
    exit 1
;;
