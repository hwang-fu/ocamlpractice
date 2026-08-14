(* Rendering parameters: the window, the drawing style, and the depth
   budget. Depth is capped because segments grow as 4^depth: depth 8 already
   draws ~200k sub-pixel segments, deeper is pointless work. *)

let window_width = 1600
let window_height = 1600
let default_depth = 4
let min_depth = 0
let max_depth = 8

(* the snowflake stays inside the circumcircle of its base triangle, so this
   ratio of the window's smaller dimension fills it with a small margin *)
let radius_ratio = 0.45
let line_width = 2
