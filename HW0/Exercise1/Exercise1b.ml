let rec nb_bits_pos n = 
    if n = 0 then
        0
    else
        (n land 1) + (nb_bits_pos (n lsr 1))

let () = Printf.printf "%d\n" (nb_bits_pos 10)