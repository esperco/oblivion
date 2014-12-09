open Printf
open Obl_types

type format = Javascript | Typescript

type options = {
  format: format;
}

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

let semicolon buf newlines_remaining =
  Buffer.add_char buf ';';
  if !newlines_remaining > 0 then (
    decr newlines_remaining;
    Buffer.add_char buf '\n'
  )

let rec print_node buf counter varprefix nl opt_parent x =
  match x with
  | Element (elt_name, opt_js_ident, attributes, children) ->
      incr counter;
      let id = !counter in
      bprintf buf "var %s%i = $(\"<%s/>\")" varprefix id elt_name;
      List.iter (print_attribute buf) attributes;
      (match opt_parent with
       | None -> ()
       | Some parent_id -> bprintf buf ".appendTo(%s%i)" varprefix parent_id
      );
      semicolon buf nl;
      (match opt_js_ident with
       | None -> ()
       | Some s ->
           bprintf buf "var %s = %s%i" s varprefix id;
           semicolon buf nl;
      );
      List.iter (print_node buf counter varprefix nl (Some id)) children
  | Data s ->
      (match opt_parent with
       | None -> () (* dropped; hopefully it's whitespace *)
       | Some parent_id ->
           bprintf buf "%s%i.append(document.createTextNode(%s))"
             varprefix parent_id (quote_js_string s);
           semicolon buf nl;
      )
  | Js_jquery s ->
      (match opt_parent with
       | None ->
           bprintf buf "(%s);" s
       | Some parent_id ->
           bprintf buf "%s%i.append(%s)" varprefix parent_id s;
           semicolon buf nl;
      )
  | Js_string s ->
      (match opt_parent with
       | None ->
           bprintf buf "(%s)" s;
           semicolon buf nl;
       | Some parent_id ->
           bprintf buf "%s%i.append(document.createTextNode(%s))"
             varprefix parent_id s;
           semicolon buf nl;
      )

let print_field ident =
  sprintf "%s: %s" ident ident

let print_fields l =
  String.concat ", " (List.map print_field l)

let extract_fields l =
  let rec aux acc l =
    List.fold_left (fun acc x ->
      match x with
      | Element (_, opt_id, _, children) ->
          let acc =
            match opt_id with
            | None -> acc
            | Some id -> id :: acc
          in
          aux acc children
      | _ ->
          acc
    ) acc l
  in
  List.rev (aux [] l)

let print_doc_elem options buf x =
  match x with
  | Js s -> Buffer.add_string buf s
  | Template (opt_view_name, l, nl_count) ->
      let view_name, varprefix =
        match opt_view_name with
        | None -> "_view", "_"
        | Some view_name -> view_name, "_" ^ view_name
      in
      let remaining_newlines = ref nl_count in
      semicolon buf remaining_newlines;
      List.iter (print_node buf (ref 0) varprefix remaining_newlines None) l;
      let fields = extract_fields l in
      bprintf buf "var %s = {%s}" view_name (print_fields fields);
      semicolon buf remaining_newlines;
      if !remaining_newlines > 0 then
        Buffer.add_string buf (String.make !remaining_newlines '\n')

let print_document ~format buf source l =
  bprintf buf "/* Auto-generated from %s by oblivion. Better not edit. */ "
    source;
  let options = {format} in
  List.iter (print_doc_elem options buf) l
