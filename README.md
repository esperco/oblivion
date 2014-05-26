Oblivion
========

Javascript/jQuery preprocessor for HTML templates with named subnodes.

What is oblivion for?
---------------------

Ever wanted to copy-paste HTML code directly into a JavaScript string?

```javascript
var s = "
<div>
  <span class="example">Welcome!</span>
</div>
";
```

Oops, that's invalid.
JavaScript doesn't support line breaks in string literals.
Instead you would have to write something like:

```javascript
var s =
 '<div>'
+'  <span class="example">Welcome!</span>'
+'</div>';
```

This required more edits than we wanted, but why not. Now something we often do
is modify child nodes based one some conditions. We use
jQuery to produce a dom node from a string, maybe as follows:

```javascript
var view = $(
 '<div>'
+'  <span class="example" id="msg"></span>'
+'</div>';
);

var text = isNewUser(user) ? "Welcome!" : "Hello!";
$("#msg").text(text);
```

Huh. This assumes that no other element in the whole document may be
identified by `id=msg`. If not, the selection `$("#msg")`
selects the wrong element. What we want here is trade our global
identifier for a JavaScript local variable. This is done as follows:

```javascript
var view = $('<div/>');
var msg = $('<span class="example"/>');
msg.appendTo(view);
var text = isNewUser(user) ? "Welcome!" : "Hello!";
msg.text(text);
```

or maybe we will push jQuery to its limits and write the following:

```javascript
var view = $('<div/>');
$('<span class="example"/>')
  .appendTo(view)
  .text(isNewUser(user) ? "Welcome!" : "Hello!");
```

Nice. No more global identifier. Does it look like HTML? No.
Do you need to create something like a modal, with a complex structure and
several placeholders for text or html elements? Still without using
global `id`'s? And everything embedded in your JavaScript source
where you need it?

This is where we figured something should be done. We came up with
`oblivion`, a preprocessor for JavaScript files that lets us write
html naturally and bind local variables to the nodes we want
without dismantling the html structure.

Oblivion syntax
---------------

Our example written in `oblivion` is:

```javascript
'''
<div #view>
  <span class="example" #msg></span>
</div>
'''
var text = isNewUser(user) ? "Welcome!" : "Hello!";
msg.text(text);
```

Also, the node variables are automatically packed into a `_view`
object that can be easily passed around to other functions. This means
that in the example above, `view` and `msg` are also available as
`_view.view` and `_view.msg`.

This is all done statically and if your html code contains syntax
errors, `oblivion` will indicate the exact position in the source file.

Syntax reference
----------------

Oblivion doesn't know anything about the JavaScript syntax. Each
occurrence of 3 or more consecutive single quotes that must be
preserved in the JavaScript output has to be escaped with an
additional single quote.
For example, `"''''"` would become `"'''"` after preprocessing.
Other than for this, source JavaScript code outside of triple
single-quote markers is left untouched.

HTML-like code must be placed within a pair 3 single quotes,
e.g. `'''<div/>'''`. This HTML-like code obeys the following rules:

* JavaScript identifiers can be placed anywhere in the list of
  attributes of an HTML element, preceded by a hash sign, e.g.
  `'''<div #jsVariable/>'''`.
* Curly braces can be used to enclose a JavaScript expression that
  evaluates to a string, e.g. '''<div>{msgText}</div>'''. An opening
  curly brace `{` can be escaped by a backslash. The contents of the
  curly braces cannot contain a closing curly brace '}'.
* Double curly braces can be used to enclose a JavaScript expression
  that evaluates to a jQuery selection,
  e.g. '''<div>{{msgBox}}</div>'''.
  An opening double curly brace `{{` can be escaped by a backslash.
  The contents of the double curly braces cannot contain a closing
  double curly brace '}}'.
* Standard HTML and XML character entities are supported.
* XML self-closing elements are supported (e.g. `<br/>`).
* Standard XML nodes (comments etc.) other than regular elements
  and data are ignored.
* All whitespace is preserved.

Further details of the syntax are left unspecified for now as they may
still change.


Command-line usage
------------------

```bash
$ mkdir -p js  # subdirectory js/ is where our pure JavaScript output ends up
$ oblivion example.js -o js/example.js
```

Installation
------------

Requirements: jQuery (JavaScript runtime only), OCaml (build time only)

`oblivion` is implemented in [OCaml](http://ocaml.org) because it is
fast and best in class for parsing. You need to install OCaml first
using your favorite package manager. For Debian-based systems such as
Ubuntu you can do `sudo apt-get install ocaml`.

Then you can build `oblivion` using `make` and install it with
`make install` or `make PREFIX=/path/to/wherever install`. By default
`PREFIX=$HOME` and the executable is `$HOME/bin/oblivion`.
