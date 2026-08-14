(* [is_leap year] returns [true] iff [year] is a leap year in the Gregorian
   calendar: divisible by 4 and not by 100, or divisible by 400. *)
let is_leap year = (year mod 4 = 0 && year mod 100 <> 0) || year mod 400 = 0
