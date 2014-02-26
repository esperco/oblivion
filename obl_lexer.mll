(*
   HTML template parser designed for Javascript and jQuery.
   UTF-8 character encoding is assumed.
*)
{
  open Printf
  open Lexing

  open Obl_types

  type html_token =
      Open_element of (string * string option * (string * string option) list)
    | Close_element of string
    | Empty_element of (string * string option * (string * string option) list)
    | Tok_data of string
    | Tok_js_jquery of string
    | Tok_js_string of string

  let pos1 lexbuf = lexbuf.lex_start_p
  let pos2 lexbuf = lexbuf.lex_curr_p
  let loc lexbuf = (pos1 lexbuf, pos2 lexbuf)

  let init_fname lexbuf fname =
    lexbuf.lex_start_p <- {
      lexbuf.lex_start_p with
      pos_fname = fname;
    };
    lexbuf.lex_curr_p <- {
      lexbuf.lex_curr_p with
      pos_fname = fname;
    }

  let newline lexbuf =
    let pos = lexbuf.lex_curr_p in
    lexbuf.lex_curr_p <- {
      pos with
      pos_lnum = pos.pos_lnum + 1;
      pos_bol = pos.pos_cnum
    }

  let string_of_loc (pos1, pos2) =
    let open Lexing in
    let line1 = pos1.pos_lnum
    and start1 = pos1.pos_bol in
    sprintf "File %S, line %i, characters %i-%i"
      pos1.pos_fname line1
      (pos1.pos_cnum - start1)
      (pos2.pos_cnum - start1)

  let error_at location msg =
    eprintf "%s:\n%s\n%!" (string_of_loc location) msg;
    failwith "Aborted"

  let error lexbuf msg =
    error_at (loc lexbuf) msg

  let fuse_cdata l =
    let rec fuse buf = function
      | Tok_data s :: l ->
          Buffer.add_string buf s;
          fuse buf l
      | l ->
          Buffer.contents buf, l
    in
    let rec scan acc = function
      | Tok_data "" :: l ->
          scan acc l
      | Tok_data _ :: _ as l ->
          let s, l = fuse (Buffer.create 100) l in
          scan (Tok_data s :: acc) l
      | x :: l ->
          scan (x :: acc) l
      | [] ->
          List.rev acc
    in
    scan [] l

  let rec close_all pending acc =
    match pending with
    | [] -> List.rev acc
    | ((name, opt_ident, attrs), parent_acc) :: pending ->
        close_all pending
          (Element (name, opt_ident, attrs, List.rev acc) :: parent_acc)

  let rec make_seq pending acc l =
    match l with
    | Open_element x :: l ->
        make_seq ((x, acc) :: pending) [] l
    | Close_element name :: l ->
        close_matching name pending acc l
    | Empty_element (name, opt_ident, attrs) :: l ->
        make_seq pending (Element (name, opt_ident, attrs, []) :: acc) l
    | Tok_data s :: l ->
        make_seq pending (Data s :: acc) l
    | Tok_js_jquery s :: l ->
        make_seq pending (Js_jquery s :: acc) l
    | Tok_js_string s :: l ->
        make_seq pending (Js_string s :: acc) l
    | [] ->
        close_all pending acc

  and close_matching cl_name pending acc l =
    match pending with
    | [] ->
        (* drop closing tag with no matching opening tag *)
        make_seq [] acc l
    | ((op_name, opt_ident, attrs), parent_acc) :: pending ->
        if op_name = cl_name then
          let node = Element (op_name, opt_ident, attrs, List.rev acc) in
          make_seq pending (node :: parent_acc) l
        else
          (* continue auto-closing until matching element is found *)
          let node = Element (op_name, opt_ident, attrs, List.rev acc) in
          close_matching cl_name pending (node :: parent_acc) l
}

let letter = ['A'-'Z' 'a'-'z']
let digit = ['0'-'9']
let hexdigit = ['0'-'9' 'A'-'F' 'a'-'f']
let namechar = letter | digit | '.' | ':' | '-' | '_'
let name = ( letter | '_' | ':' ) namechar*
let ws = [ ' ' '\t' '\r' '\n' ]
let unquoted_attribute = [^ '"' '\'' '>' ' ' '\t' '\n' '\r' ]+

let js_ident = ['A'-'Z' 'a'-'z' '_' '$']['A'-'Z' 'a'-'z' '_' '$' '0'-'9']*

rule parse_document = parse
  | [^'\'' '\n']+ as s
                  { Js s :: parse_document lexbuf }
  | '\n'          { newline lexbuf;
                    Js "\n" :: parse_document lexbuf }
  | "'''"         { let x = make_seq [] [] (parse_html [] lexbuf) in
                    Template x :: parse_document lexbuf }
  | "'" ("''" ['\'']+ as s)
                  { Js s :: parse_document lexbuf }
  | _ as c        { Js (String.make 1 c) :: parse_document lexbuf }
  | eof           { [] }

and parse_html acc = parse

  (* Standard HTML *)

  | "<!--" ([^'-'] | '-'[^'-'])* "-->"
      { (* ignore comment *)
        parse_html acc lexbuf }
  | "<!" [^'>']* ">"
      { (* ignore doctype *)
        parse_html acc lexbuf }
  | "<?" [^'>']* "?>"
      { (* ignore xml processing instruction *)
        parse_html acc lexbuf }
  | "<" (name as elt_name)
      { let closed, opt_ident, l = parse_attributes None [] lexbuf in
        let elt_name = String.lowercase elt_name in
        let x =
          if closed then
            Empty_element (elt_name, opt_ident, l)
          else
            Open_element (String.lowercase elt_name, opt_ident, l)
        in
        parse_html (x :: acc) lexbuf }
  | "</" (name as elt_name) ws* ">"
      { let x = Close_element elt_name in
        parse_html (x :: acc) lexbuf }
  | "&"
      { let x = parse_entity lexbuf in
        parse_html (Tok_data x :: acc) lexbuf }
  | "<"
      { (* tolerate unescaped "<" *)
        parse_html (Tok_data "<" :: acc) lexbuf }
  | [^ '<' '&' '\'' '{' '\\']+ as s
      { parse_html (Tok_data s :: acc) lexbuf }

  (* Template syntax *)

  | "'''"
      { fuse_cdata (List.rev acc) }
  | "'" ("''" ['\'']+ as s)
      { parse_html (Tok_data s :: acc) lexbuf }
  | "{{" ([^'{' '}']* as s) "}}"
      { parse_html (Tok_js_jquery s :: acc) lexbuf }
  | "{" ([^'{' '}']* as s) "}"
      { parse_html (Tok_js_string s :: acc) lexbuf }
  | "\\{"
      { parse_html (Tok_data "{" :: acc) lexbuf }

  | _ as c
      { parse_html (Tok_data (String.make 1 c) :: acc) lexbuf }
  | eof
      { error lexbuf "Missing closing triple quote (''')" }

and parse_entity = parse
  | "#x" (hexdigit hexdigit as s) ";"
      { Obl_utf8.string_of_unicode (int_of_string ("0x" ^ s)) }
  | (name as name) ";"
      { Obl_html.string_of_entity_name name }
  | ""
      { (* tolerate unescaped "&" *)
        "&" }

and parse_attributes opt_ident acc = parse

  (* Standard HTML *)

  | ">"
      { false, opt_ident, List.rev acc }
  | "/>"
      { true, opt_ident, List.rev acc }
  | ws+
      { parse_attributes opt_ident acc lexbuf }

  | (name as k)
      { parse_attributes opt_ident
          ((String.lowercase k, None) :: acc) lexbuf }

  | (name as k) ws* "=" (unquoted_attribute as v)
      { parse_attributes opt_ident
          ((String.lowercase k, Some v) :: acc) lexbuf }

  | (name as k) ws* "=" ws* '"'
      { let v = parse_string_literal1 (Buffer.create 100) lexbuf in
        parse_attributes opt_ident
          ((String.lowercase k, Some v) :: acc) lexbuf }

  | (name as k) ws* "=" ws* "'"
      { let v = parse_string_literal2 (Buffer.create 100) lexbuf in
        parse_attributes opt_ident
          ((String.lowercase k, Some v) :: acc) lexbuf }


  (* Template syntax *)

  | "#" (js_ident as s)
      { let opt_ident =
        match opt_ident with
        | None -> Some s
        | Some s0 ->
            error lexbuf
              (sprintf "Multiple variables bound to the same node: #%s #%s"
                 s0 s)
        in
        parse_attributes opt_ident acc lexbuf
      }

  | _
      { (* ignore junk *)
        parse_attributes opt_ident acc lexbuf }

  | eof
      { error lexbuf "End of file reached within attribute list" }

and parse_string_literal1 buf = parse
  | ( [^ '"' '&']* as s)
      { Buffer.add_string buf s;
        parse_string_literal1 buf lexbuf }
  | "&"
      { Buffer.add_string buf (parse_entity lexbuf);
        parse_string_literal1 buf lexbuf }
  | '"'
      { Buffer.contents buf }
  | eof
      { error lexbuf "Unterminated string literal: missing double quote" }

and parse_string_literal2 buf = parse
  | ( [^ '\'' '&']* as s)
      { Buffer.add_string buf s;
        parse_string_literal2 buf lexbuf }
  | "&"
      { Buffer.add_string buf (parse_entity lexbuf);
        parse_string_literal2 buf lexbuf }
  | '\''
      { Buffer.contents buf }
  | eof
      { error lexbuf "Unterminated string literal: missing single quote" }

{
  let parse source lexbuf =
    init_fname lexbuf source;
    parse_document lexbuf

  let from_channel source ic =
    let lexbuf = Lexing.from_channel ic in
    parse source lexbuf
}
