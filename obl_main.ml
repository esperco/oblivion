open Printf

let run ~format source ic oc =
  let document = Obl_lexer.from_channel source ic in
  let buf = Buffer.create 1000 in
  Obl_print.print_document ~format buf source document;
  output_string oc (Buffer.contents buf);
  flush oc

let main () =
  let out_file = ref None in
  let in_file = ref None in
  let format = ref Obl_print.Javascript in
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

    "-js",
    Arg.Unit (fun () -> format := Obl_print.Javascript),
    "
          Produce JavaScript code (default)";

    "-ts",
    Arg.Unit (fun () -> format := Obl_print.Typescript),
    "
          Produce TypeScript code";
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
  run ~format: !format source ic oc

let () = main ()
