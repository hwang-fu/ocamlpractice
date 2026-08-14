let () =
  assert (Leap.is_leap 2024);
  assert (not (Leap.is_leap 2023));
  assert (not (Leap.is_leap 1900));
  assert (Leap.is_leap 2000);
  print_endline "all tests passed"
;;
