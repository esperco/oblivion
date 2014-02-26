open Printf
open Obl_types

let quote_js_string s =
  let buf = Buffer.create (2 * String.length s) in
  Buffer.add_char buf '"';
  for i = 0 to String.length s - 1 do
    match s.[i] with
    | '"' -> Buffer.add_string buf "\\\""
    | '\n' -> Buffer.add_string buf "\\n"
    | '\\' -> Buffer.add_string buf "\\\\"
    | c -> Buffer.add_char buf c
  done;
  Buffer.add_char buf '"';
  Buffer.contents buf

let print_attribute buf (name, opt_value) =
  let v =
    match opt_value with
    | None -> "true"
    | Some s -> quote_js_string s
  in
  bprintf buf ".attr(%s, %s)" (quote_js_string name) v

let rec print_node buf counter opt_parent x =
  match x with
  | Element (elt_name, opt_js_ident, attributes, children) ->
      incr counter;
      let id = !counter in
      bprintf buf "var _%i = $(\"<%s/>\")" id elt_name;
      List.iter (print_attribute buf) attributes;
      (match opt_parent with
       | None -> ()
       | Some parent_id -> bprintf buf ".appendTo(_%i)" parent_id
      );
      bprintf buf ";\n";
      (match opt_js_ident with
       | None -> ()
       | Some s -> bprintf buf "var %s = _%i;\n" s id
      );
      List.iter (print_node buf counter (Some id)) children
  | Data s ->
      (match opt_parent with
       | None -> () (* dropped; hopefully it's whitespace *)
       | Some parent_id ->
           bprintf buf "_%i.append(document.createTextNode(%s));\n"
             parent_id (quote_js_string s)
      )
  | Js_jquery s ->
      (match opt_parent with
       | None ->
           bprintf buf "(%s);" s
       | Some parent_id ->
           bprintf buf "_%i.append(%s);\n" parent_id s
      )
  | Js_string s ->
      (match opt_parent with
       | None ->
           bprintf buf "(%s);" s
       | Some parent_id ->
           bprintf buf "_%i.append(document.createTextNode(%s));\n"
             parent_id s
      )

let print_doc_elem buf x =
  match x with
  | Js s -> Buffer.add_string buf s
  | Template l ->
      List.iter (print_node buf (ref 0) None) l

let print_document buf source l =
  bprintf buf "/* Auto-generated from %s by oblivion. Better not edit. */ "
    source;
  List.iter (print_doc_elem buf) l
