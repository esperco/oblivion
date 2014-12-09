type node =
  | Element of string              (* element name *)
               * string option     (* optional Javascript identifier *)
               * (string * string option) list (* attributes *)
               * node list         (* children *)
  | Data of string
  | Js_jquery of string
  | Js_string of string

type template = node list

type doc_elem =
  | Js of string
  | Template of (string option (* custom name for the _view variable *)
                 * template
                 * int (* newline count *))

type document = doc_elem list
