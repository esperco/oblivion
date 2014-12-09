function render(title, name) {
  var escaped = "3 single quotes: ''''";
'''
<!doctype html>
<html>
<head>
  <title>{title}</title>
</head>
<body #body>
  {{stuff}}
  <h1 #headline>{ title + ' ' + title.toUpperCase() }</h\
  1>
  <p>
    Hello {name}!
  </p>
  <p>
    open-curly a b c close-curly = \{abc}
  </p>
  <p>
    3 single quotes: ''''
  </p>
  <input type="radio" checked />
</body>
</html>
'''

  '''another_view <b #woof>Woof!</b>'''

  return [ body, headline ];
}
