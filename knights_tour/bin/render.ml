open Graphics

let win = 900
let board_px = 840

(* the whole tour animates over this many seconds whatever the board size *)
let total_duration = 30.0
let frames_per_jump = 16
let path_color = rgb 30 60 160
let closing_color = rgb 200 30 30

let animate ~n tour =
  open_graph (Printf.sprintf " %dx%d" win win);
  set_window_title "Knight's tour";
  (* every frame redraws the whole scene off-screen and flips it in, so the
     moving arrow never leaves droppings on the board *)
  auto_synchronize false;
  let cell = board_px / n in
  let x0 = (win - (cell * n)) / 2 in
  let tour = Array.of_list tour in
  let m = Array.length tour in
  let center i =
    let cx, cy = tour.(i) in
    x0 + (cx * cell) + (cell / 2), x0 + (cy * cell) + (cell / 2)
  in
  let light = rgb 240 217 181
  and dark = rgb 181 136 99 in
  let draw_board () =
    for r = 0 to n - 1 do
      for c = 0 to n - 1 do
        set_color (if (r + c) mod 2 = 0 then light else dark);
        fill_rect (x0 + (c * cell)) (x0 + (r * cell)) cell cell
      done
    done
  in
  (* the segment from [a] toward [b], drawn up to fraction [frac], tipped
     with a small arrowhead pointing along the travel direction *)
  let draw_arrow (ax, ay) (bx, by) frac =
    let dx = float (bx - ax)
    and dy = float (by - ay) in
    let tx = float ax +. (dx *. frac)
    and ty = float ay +. (dy *. frac) in
    let len = sqrt ((dx *. dx) +. (dy *. dy)) in
    let ux = dx /. len
    and uy = dy /. len in
    moveto ax ay;
    lineto (truncate tx) (truncate ty);
    fill_poly
      [| truncate tx, truncate ty
       ; ( truncate (tx -. (12. *. ux) +. (5. *. uy))
         , truncate (ty -. (12. *. uy) -. (5. *. ux)) )
       ; ( truncate (tx -. (12. *. ux) -. (5. *. uy))
         , truncate (ty -. (12. *. uy) +. (5. *. ux)) )
      |]
  in
  (* [completed] jumps are final; [current] is an in-flight jump as
     (source index, target index, fraction, color) *)
  let draw_scene completed current =
    draw_board ();
    set_line_width 2;
    set_color path_color;
    for i = 0 to completed - 1 do
      let ax, ay = center i
      and bx, by = center (i + 1) in
      moveto ax ay;
      lineto bx by
    done;
    set_color black;
    for i = 0 to completed do
      let cx, cy = center i in
      moveto (cx + 6) (cy + 6);
      draw_string (string_of_int (i + 1))
    done;
    (match current with
     | None -> ()
     | Some (src, dst, frac, color) ->
       set_color color;
       draw_arrow (center src) (center dst) frac);
    synchronize ()
  in
  let frame_sleep = total_duration /. float m /. float frames_per_jump in
  let fly completed src dst color =
    for f = 1 to frames_per_jump do
      draw_scene completed (Some (src, dst, float f /. float frames_per_jump, color));
      Unix.sleepf frame_sleep
    done
  in
  for j = 0 to m - 2 do
    fly j j (j + 1) path_color
  done;
  (* the closing move, highlighted *)
  fly (m - 1) (m - 1) 0 closing_color;
  let lx, ly = center (m - 1)
  and fx, fy = center 0 in
  set_color closing_color;
  moveto lx ly;
  lineto fx fy;
  synchronize ();
  try ignore (read_key ()) with
  | Graphic_failure _ -> ()
;;
