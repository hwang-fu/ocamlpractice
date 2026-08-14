(** Pure Koch-curve geometry; drawing lives in the executable. *)

type point = float * float

(** [koch depth a b] is the polyline of the Koch curve of [depth] from [a]
    to [b]: a list of [4 ^ depth + 1] points starting at [a] and ending at
    [b]. The bump of each subdivision grows to the left of the direction of
    travel. *)
val koch : int -> point -> point -> point list
