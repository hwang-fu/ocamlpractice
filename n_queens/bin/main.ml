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

type button =
  { rect : rect
  ; label : string
  }

let prev_button = { rect = { x = 80; y = 40; w = 140; h = 50 }; label = "< Prev" }
let next_button = { rect = { x = 480; y = 40; w = 140; h = 50 }; label = "Next >" }
let inside r mx my = mx >= r.x && mx <= r.x + r.w && my >= r.y && my <= r.y + r.h

(* Graphics has no rounded-rectangle primitive: build one from two
   overlapping rectangles (the horizontal and vertical bars of a cross) and
   a filled circle in each corner. *)
let fill_round_rect x y w h rad =
  fill_rect (x + rad) y (w - (2 * rad)) h;
  fill_rect x (y + rad) w (h - (2 * rad));
  fill_circle (x + rad) (y + rad) rad;
  fill_circle (x + w - rad) (y + rad) rad;
  fill_circle (x + rad) (y + h - rad) rad;
  fill_circle (x + w - rad) (y + h - rad) rad
;;

(* The button face floats a few pixels above a drop shadow; pressing drops
   the face onto it (label riding along), which the eye reads as the button
   sinking. *)
let draw_button ?(pressed = false) b =
  let r = b.rect in
  let rad = 12 in
  let lift = if pressed then 0 else 3 in
  (* erase the full extent first: the raised face sticks 3px above the
     pressed one, and a stale strip would survive the state switch *)
  set_color white;
  fill_rect r.x r.y r.w (r.h + 3);
  set_color (rgb 120 120 120);
  fill_round_rect r.x r.y r.w r.h rad;
  set_color (rgb 225 225 225);
  fill_round_rect r.x (r.y + lift) r.w r.h rad;
  let tw, th = text_size b.label in
  set_color black;
  moveto (r.x + ((r.w - tw) / 2)) (r.y + ((r.h - th) / 2) + lift);
  draw_string b.label
;;

let draw_board n queens =
  let cell = board_px / n in
  let x0 = (win_w - (cell * n)) / 2 in
  let y0 = 150 in
  let light = rgb 240 217 181
  and dark = rgb 181 136 99 in
  for r = 0 to n - 1 do
    for c = 0 to n - 1 do
      set_color (if (r + c) mod 2 = 0 then light else dark);
      fill_rect (x0 + (c * cell)) (y0 + (r * cell)) cell cell
    done
  done;
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
  draw_button prev_button;
  draw_button next_button
;;

(* The UI is a small state machine written as three mutually recursive
   functions: [loop] redraws and idles, [idle] waits for input without
   redrawing, and [held] is the pressed-button phase. The displayed solution
   index travels as an argument -- no mutable state. *)
let rec loop n sols idx =
  draw_state n sols idx;
  idle n sols idx

and idle n sols idx =
  let e = wait_next_event [ Button_down; Key_pressed ] in
  let total = Array.length sols in
  let next = (idx + 1) mod total
  and prev = (idx + total - 1) mod total in
  if e.button
  then
    if inside prev_button.rect e.mouse_x e.mouse_y
    then held n sols idx prev_button prev
    else if inside next_button.rect e.mouse_x e.mouse_y
    then held n sols idx next_button next
    else idle n sols idx
  else (
    match e.key with
    | 'n' -> loop n sols next
    | 'p' -> loop n sols prev
    | 'q' -> ()
    | _ -> idle n sols idx)

(* [b] stays drawn pressed until the mouse button is released; the click
   fires (jumping to solution [target]) only if the release lands inside
   [b] -- releasing elsewhere cancels, like a native button. *)
and held n sols idx b target =
  draw_button ~pressed:true b;
  let e = wait_next_event [ Button_up ] in
  if inside b.rect e.mouse_x e.mouse_y then loop n sols target else loop n sols idx
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
