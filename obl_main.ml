open Printf

let run source ic oc =
  let document = Obl_lexer.from_channel source ic in
  let buf = Buffer.create 1000 in
  Obl_print.print_document buf source document;
  output_string oc (Buffer.contents buf);
  flush oc

let main () =
  let out_file = ref None in
  let in_file = ref None in
  let options = [
    "-o",
    Arg.String (
      fun s ->
        if !out_file <> None then
          failwith "Multiple output files"
        else
          out_file := Some s
    ),
    "<file>
          Output file (default: output goes to stdout)";
  ]
  in
  let anon_fun s =
    if !in_file <> None then
      failwith "Multiple input files"
    else
      in_file := Some s
  in

  let usage_msg = sprintf "\
Usage: %s [input file] [options]

Preprocess Javascript file containing embedded HTML templates.

Command-line options:
"
      Sys.argv.(0)
  in

  Arg.parse options anon_fun usage_msg;

  let ic, source =
    match !in_file with
      None -> stdin, "<stdin>"
    | Some file -> open_in file, file
  in
  let oc =
    match !out_file with
      None -> stdout
    | Some file -> open_out file
  in
  run source ic oc

let () = main ()
