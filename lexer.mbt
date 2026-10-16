///|
pub(all) struct Token {
  text : String
  offset : Int
}

///|
pub fn ident_start(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

///|
pub fn ident_continue(c : Char) -> Bool {
  ident_start(c) || (c >= '0' && c <= '9')
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
    if c == ' ' || c == '\n' || c == '\r' || c == '\t' {
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
    if ident_start(c) || (c >= '0' && c <= '9') || c == '-' {
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

///|
/// Constant syntax follows C decimal, octal and hexadecimal, within signed 32-bit.
pub fn parse_constant_number(
  text : String,
  offset? : Int = 0,
) -> Int raise XdrError {
  let cs = text.to_array()
  let mut i = 0
  let negative = cs.length() > 0 && cs[0] == '-'
  if negative {
    i = 1
  }
  if i >= cs.length() {
    raise Invalid(offset, "missing integer digits")
  }
  let mut radix = 10L
  if i + 1 < cs.length() && cs[i] == '0' {
    if cs[i + 1] == 'x' || cs[i + 1] == 'X' {
      radix = 16L
      i += 2
    } else {
      radix = 8L
    }
  }
  if i >= cs.length() {
    raise Invalid(offset, "missing hexadecimal digits")
  }
  let mut n = 0L
  let bound = if negative { 2147483648L } else { 2147483647L }
  while i < cs.length() {
    let c = cs[i]
    let digit = if c >= '0' && c <= '9' {
      c.to_int() - 48
    } else if c >= 'a' && c <= 'f' {
      c.to_int() - 87
    } else if c >= 'A' && c <= 'F' {
      c.to_int() - 55
    } else {
      raise Invalid(offset + i, "invalid integer digit")
    }
    if digit.to_int64() >= radix || n > (bound - digit.to_int64()) / radix {
      raise Invalid(offset + i, "integer out of range")
    }
    n = n * radix + digit.to_int64()
    i += 1
  }
  (if negative { -n } else { n }).to_int()
}
