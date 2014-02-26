(* taken from Utf8val *)
let utf8_encode buf x =
  (* Straight <= doesn't work with signed 31-bit ints
     (which are outside of Unicode but supported by UTF-8) *)
  let maxbits n x = x lsr n = 0 in
  let add = Buffer.add_char in

  if maxbits 7 x then
    (* 7 *)
    add buf (Char.chr x)
  else if maxbits 11 x then (
    (* 5 + 6 *)
    add buf (Char.chr (0b11000000 lor ((x lsr 6) land 0b00011111)));
    add buf (Char.chr (0b10000000 lor (x         land 0b00111111)))
  )
  else if maxbits 16 x then (
    (* 4 + 6 + 6 *)
    add buf (Char.chr (0b11100000 lor ((x lsr 12) land 0b00001111)));
    add buf (Char.chr (0b10000000 lor ((x lsr  6) land 0b00111111)));
    add buf (Char.chr (0b10000000 lor (x          land 0b00111111)))
  )
  else if maxbits 21 x then (
    (* 3 + 6 + 6 + 6 *)
    add buf (Char.chr (0b11110000 lor ((x lsr 18) land 0b00000111)));
    add buf (Char.chr (0b10000000 lor ((x lsr 12) land 0b00111111)));
    add buf (Char.chr (0b10000000 lor ((x lsr  6) land 0b00111111)));
    add buf (Char.chr (0b10000000 lor (x          land 0b00111111)));
  )
  else if maxbits 26 x then (
    (* 2 + 6 + 6 + 6 + 6 *)
    add buf (Char.chr (0b11111000 lor ((x lsr 24) land 0b00000011)));
    add buf (Char.chr (0b10000000 lor ((x lsr 18) land 0b00111111)));
    add buf (Char.chr (0b10000000 lor ((x lsr 12) land 0b00111111)));
    add buf (Char.chr (0b10000000 lor ((x lsr  6) land 0b00111111)));
    add buf (Char.chr (0b10000000 lor (x          land 0b00111111)));
  )
  else (
    assert (maxbits 31 x);
    (* 1 + 6 + 6 + 6 + 6 + 6 *)
    add buf (Char.chr (0b11111100 lor ((x lsr 30) land 0b00000001)));
    add buf (Char.chr (0b10000000 lor ((x lsr 24) land 0b00111111)));
    add buf (Char.chr (0b10000000 lor ((x lsr 18) land 0b00111111)));
    add buf (Char.chr (0b10000000 lor ((x lsr 12) land 0b00111111)));
    add buf (Char.chr (0b10000000 lor ((x lsr  6) land 0b00111111)));
    add buf (Char.chr (0b10000000 lor (x          land 0b00111111)));
  )

let string_of_unicode n =
  let buf = Buffer.create 6 in
  utf8_encode buf n;
  Buffer.contents buf
