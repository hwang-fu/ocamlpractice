open Graphics

let win = 900
let board_px = 840

(* the whole tour animates over this many seconds whatever the board size *)
let total_duration = 12.0

let animate ~n tour =
  open_graph (Printf.sprintf " %dx%d" win win);
  set_window_title "Knight's tour";
  let cell = board_px / n in
  let x0 = (win - (cell * n)) / 2 in
  let y0 = x0 in
  let center (cx, cy) = x0 + (cx * cell) + (cell / 2), y0 + (cy * cell) + (cell / 2) in
  let light = rgb 240 217 181
  and dark = rgb 181 136 99 in
  for r = 0 to n - 1 do
    for c = 0 to n - 1 do
      set_color (if (r + c) mod 2 = 0 then light else dark);
      fill_rect (x0 + (c * cell)) (y0 + (r * cell)) cell cell
    done
  done;
  let delay = total_duration /. float (n * n) in
  set_line_width 2;
  (* draw the jump [prev] -> [sq] and stamp [sq] with its visit number *)
  let step i prev sq =
    let px, py = center prev
    and qx, qy = center sq in
    set_color (rgb 30 60 160);
    moveto px py;
    lineto qx qy;
    fill_circle qx qy 4;
    set_color black;
    moveto (qx + 6) (qy + 6);
    draw_string (string_of_int i);
    synchronize ();
    Unix.sleepf delay
  in
  (match tour with
   | [] -> ()
   | first :: rest ->
     let fx, fy = center first in
     set_color (rgb 30 60 160);
     fill_circle fx fy 5;
     set_color black;
     moveto (fx + 6) (fy + 6);
     draw_string "1";
     let _ =
       List.fold_left
         (fun (i, prev) sq ->
            step i prev sq;
            i + 1, sq)
         (2, first)
         rest
     in
     (* the closing move, highlighted *)
     let lx, ly = center (List.nth tour (List.length tour - 1)) in
     set_color (rgb 200 30 30);
     moveto lx ly;
     lineto fx fy;
     synchronize ());
  try ignore (read_key ()) with
  | Graphic_failure _ -> ()
;;
