open Graphics

(* window and board geometry, in pixels; the board sits centered *)
let win = 920
let cell_px = 90
let board_px = cell_px * 9
let margin = (win - board_px) / 2

(* the board itself is light grey; digits are bold black (givens), green
   (deductions) or orange (guesses); highlights explain the reasoning *)
let board_grey = rgb 235 235 235
let mark_grey = rgb 130 130 130
let deduced_green = rgb 20 130 50
let guess_orange = rgb 225 120 20
let guess_bg = rgb 255 224 178
let flash_red = rgb 225 60 60
let focus_yellow = rgb 255 240 150
let unit_blue = rgb 208 226 250

(* pacing: givens pour in quickly, each deduction lingers, and a
   contradiction holds longest so the red flash registers *)
let givens_delay = 0.04
let step_delay = 0.35
let flash_delay = 0.8

(* X core fonts; if a font is missing we silently keep the current one *)
let digit_font = "-*-helvetica-bold-r-normal--34-*-*-*-*-*-iso8859-1"
let mark_font = "-*-helvetica-medium-r-normal--12-*-*-*-*-*-iso8859-1"

let try_font f =
  try set_font f with
  | Graphic_failure _ -> ()
;;

(* how a digit arrived on the board; decides its color *)
type kind =
  | KGiven
  | KDeduced
  | KGuess

(* [kind_color k] is the drawing color of a digit of kind [k]. *)
let kind_color = function
  | KGiven -> black
  | KDeduced -> deduced_green
  | KGuess -> guess_orange
;;

(* screen origin (lower-left) of cell [c]; row 0 is drawn at the top *)
let cell_origin c =
  let col = c mod 9
  and row = c / 9 in
  margin + (col * cell_px), margin + ((8 - row) * cell_px)
;;

(* [draw_centered_string x y s] draws [s] centered on the point (x, y),
   measuring it in the currently selected font. *)
let draw_centered_string x y s =
  let tw, th = text_size s in
  moveto (x - (tw / 2)) (y - (th / 2));
  draw_string s
;;

(* Full frame: highlighted cells first, then the grid, digits and pencil
   marks; flipped in at once to keep the animation steady. *)
let draw_scene digits kinds highlights =
  set_color white;
  fill_rect 0 0 win win;
  for c = 0 to 80 do
    let x, y = cell_origin c in
    set_color
      (match List.assoc_opt c highlights with
       | Some color -> color
       | None -> board_grey);
    fill_rect x y cell_px cell_px
  done;
  for i = 0 to 9 do
    let heavy = i mod 3 = 0 in
    set_color (if heavy then black else rgb 170 170 170);
    set_line_width (if heavy then 3 else 1);
    let p = margin + (i * cell_px) in
    moveto margin p;
    lineto (margin + board_px) p;
    moveto p margin;
    lineto p (margin + board_px)
  done;
  for c = 0 to 80 do
    let x, y = cell_origin c in
    if digits.(c) <> 0
    then (
      try_font digit_font;
      set_color (kind_color kinds.(c));
      draw_centered_string
        (x + (cell_px / 2))
        (y + (cell_px / 2))
        (string_of_int digits.(c)))
    else (
      (* pencil marks, laid out as a mini 3x3 grid inside the cell *)
      try_font mark_font;
      set_color mark_grey;
      List.iter
        (fun d ->
           let sub = cell_px / 3 in
           let sx = x + ((d - 1) mod 3 * sub) + (sub / 2)
           and sy = y + cell_px - (((d - 1) / 3 * sub) + (sub / 2)) in
           draw_centered_string sx sy (string_of_int d))
        (Sudoku.candidates digits c))
  done;
  synchronize ()
;;

(* Replay the reasoning trace as a tutor: highlight what is about to
   happen, then let it happen. Guesses snapshot the board so [Backtrack]
   can rewind it. *)
let run trace =
  open_graph (Printf.sprintf " %dx%d" win win);
  set_window_title "Sudoku tutor";
  auto_synchronize false;
  let digits = Array.make 81 0
  and kinds = Array.make 81 KGiven in
  (* board snapshots taken at each guess, popped on backtrack *)
  let stack = ref [] in
  (* [show ~hl ~delay ()] draws the current board with the given cell
     highlights and pauses *)
  let show ?(hl = []) ?(delay = step_delay) () =
    draw_scene digits kinds hl;
    Unix.sleepf delay
  in
  List.iter
    (fun step ->
       match (step : Sudoku.step) with
       | Given (c, d) ->
         digits.(c) <- d;
         kinds.(c) <- KGiven;
         show ~delay:givens_delay ()
       | Naked (c, d) ->
         (* the yellow cell's marks have shrunk to one: that is the why *)
         show ~hl:[ c, focus_yellow ] ();
         digits.(c) <- d;
         kinds.(c) <- KDeduced;
         show ~hl:[ c, focus_yellow ] ()
       | Hidden (c, d, u) ->
         (* within the blue unit, the placed digit's mark appears only in
            the yellow cell: that is the why *)
         let hl =
           (c, focus_yellow) :: List.map (fun c' -> c', unit_blue) (Sudoku.cells_of u)
         in
         show ~hl ();
         digits.(c) <- d;
         kinds.(c) <- KDeduced;
         show ~hl ()
       | Guess (c, d) ->
         (* snapshot first, so a later Backtrack restores the pre-guess
            board exactly *)
         stack := (Array.copy digits, Array.copy kinds) :: !stack;
         show ~hl:[ c, guess_bg ] ();
         digits.(c) <- d;
         kinds.(c) <- KGuess;
         show ~hl:[ c, guess_bg ] ()
       (* the emptied cell flashes red; the board itself is untouched *)
       | Contradiction c -> show ~hl:[ c, flash_red ] ~delay:flash_delay ()
       (* rewind to the snapshot of the failed guess (an empty stack can
          only mean contradictory givens: nothing to rewind) *)
       | Backtrack ->
         (match !stack with
          | [] -> ()
          | (d0, k0) :: rest ->
            stack := rest;
            Array.blit d0 0 digits 0 81;
            Array.blit k0 0 kinds 0 81;
            show ()))
    trace;
  show ~delay:0. ();
  try ignore (read_key ()) with
  | Graphic_failure _ -> ()
;;
