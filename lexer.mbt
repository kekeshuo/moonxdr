///|
pub(all) struct Token {
  text : String
  offset : Int
}

///|
pub fn ident_start(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
pub fn ident_continue(c : Char) -> Bool {
  ident_start(c) || (c >= '0' && c <= '9') || c == '_'
}

///|
/// Lexer preserves source character offsets and rejects unsupported directives.
pub fn tokenize(
  source : String,
  limits? : Limits = Limits::default(),
) -> Array[Token] raise XdrError {
  limits.validate()
  if source.length() > limits.max_bytes {
    raise Invalid(0, "schema byte limit")
  }
  let cs = source.to_array()
  let out : Array[Token] = []
  let mut i = 0
  while i < cs.length() {
    let c = cs[i]
    if c == ' ' ||
      c == '\n' ||
      c == '\r' ||
      c == '\t' ||
      c == '\u000b' ||
      c == '\u000c' {
      i += 1
      continue
    }
    if c == '/' && i + 1 < cs.length() && cs[i + 1] == '/' {
      i += 2
      while i < cs.length() && cs[i] != '\n' {
        i += 1
      }
      continue
    }
    if c == '/' && i + 1 < cs.length() && cs[i + 1] == '*' {
      let start = i
      i += 2
      while i + 1 < cs.length() && !(cs[i] == '*' && cs[i + 1] == '/') {
        i += 1
      }
      if i + 1 >= cs.length() {
        raise Invalid(start, "unterminated comment")
      }
      i += 2
      continue
    }
    let start = i
    if ident_start(c) || (c >= '0' && c <= '9') || c == '_' || c == '-' {
      i += 1
      while i < cs.length() && ident_continue(cs[i]) {
        i += 1
      }
    } else if c == '{' ||
      c == '}' ||
      c == '[' ||
      c == ']' ||
      c == '<' ||
      c == '>' ||
      c == '(' ||
      c == ')' ||
      c == '*' ||
      c == ';' ||
      c == ':' ||
      c == ',' ||
      c == '=' {
      i += 1
    } else {
      raise Invalid(start, "unsupported schema character")
    }
    if out.length() >= limits.max_schema_tokens {
      raise Invalid(start, "schema token limit")
    }
    out.push({
      text: String::from_array(cs.exact_view(start~, end=i)),
      offset: start,
    })
  }
  out.push({ text: "", offset: source.length(), })
  out
}
