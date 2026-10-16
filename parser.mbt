///|
pub struct Parser {
  tokens : Array[Token]
  mut cursor : Int
  schema : Schema
}

///|
pub fn Parser::new(
  source : String,
  limits? : Limits = Limits::default(),
) -> Parser raise XdrError {
  {
    tokens: tokenize(source, limits~),
    cursor: 0,
    schema: Schema::empty(limits~),
  }
}

///|
pub fn Parser::peek(self : Parser) -> String {
  self.tokens[self.cursor].text
}

///|
pub fn Parser::offset(self : Parser) -> Int {
  self.tokens[self.cursor].offset
}

///|
pub fn Parser::take(self : Parser) -> String raise XdrError {
  let s = self.peek()
  if s == "" {
    raise Invalid(self.offset(), "unexpected end of schema")
  }
  self.cursor += 1
  s
}

///|
pub fn Parser::expect(self : Parser, expected : String) -> Unit raise XdrError {
  if self.peek() != expected {
    raise Invalid(self.offset(), "expected " + expected)
  }
  ignore(self.take())
}

///|
pub fn Parser::identifier(self : Parser) -> String raise XdrError {
  let s = self.peek()
  if s == "" || !ident_start(s.to_array()[0]) {
    raise Invalid(self.offset(), "expected identifier")
  }
  match s {
    "const"
    | "typedef"
    | "enum"
    | "struct"
    | "union"
    | "switch"
    | "case"
    | "default"
    | "unsigned"
    | "int"
    | "hyper"
    | "float"
    | "double"
    | "quadruple"
    | "bool"
    | "opaque"
    | "string"
    | "void" => raise Invalid(self.offset(), "reserved identifier")
    _ => self.take()
  }
}

///|
pub fn Parser::value(self : Parser) -> Int raise XdrError {
  let offset = self.offset()
  let s = self.take()
  match self.schema.constants.get(s) {
    Some(n) => n
    None =>
      if s == "TRUE" {
        1
      } else if s == "FALSE" {
        0
      } else {
        parse_constant_number(s, offset~)
      }
  }
}

///|
pub fn Parser::bound(self : Parser, closing : String) -> Int raise XdrError {
  let n = if self.peek() == closing {
    self.schema.limits.max_items
  } else {
    self.value()
  }
  if n < 0 {
    raise Invalid(self.offset(), "negative bound")
  }
  self.expect(closing)
  n
}

///|
pub fn Parser::base_type(self : Parser, depth : Int) -> Type raise XdrError {
  if depth > self.schema.limits.max_depth {
    raise Invalid(self.offset(), "schema nesting limit")
  }
  match self.take() {
    "void" => TVoid
    "enum" => self.compound("enum", depth + 1)
    "struct" => self.compound("struct", depth + 1)
    "union" => self.compound("union", depth + 1)
    "int" => TInt
    "hyper" => THyper
    "bool" => TBool
    "float" => TFloat
    "double" => TDouble
    "unsigned" =>
      match self.take() {
        "int" => TUInt
        "hyper" => TUHyper
        _ => raise Invalid(self.offset(), "unsigned requires int or hyper")
      }
    name => {
      if name == "" || !ident_start(name.to_array()[0]) {
        raise Invalid(self.offset(), "expected type")
      }
      TRef(name)
    }
  }
}

///|
pub fn Parser::declaration(self : Parser, depth : Int) -> Field raise XdrError {
  if self.peek() == "opaque" || self.peek() == "string" {
    let kind = self.take()
    let name = self.identifier()
    if self.peek() == "[" && kind == "opaque" {
      self.expect("[")
      let n = self.bound("]")
      return { name, ty: TOpaque(n, false), }
    }
    self.expect("<")
    let n = self.bound(">")
    return {
      name,
      ty: if kind == "string" {
        TString(n)
      } else {
        TOpaque(n, true)
      },
    }
  }
  let base = self.base_type(depth)
  let pointer = self.peek() == "*"
  if pointer {
    self.expect("*")
  }
  let name = self.identifier()
  let ty = if pointer {
    TOptional(base)
  } else if self.peek() == "[" {
    self.expect("[")
    TArray(base, self.bound("]"), false)
  } else if self.peek() == "<" {
    self.expect("<")
    TArray(base, self.bound(">"), true)
  } else {
    base
  }
  { name, ty, }
}

///|
pub fn Parser::add_type(
  self : Parser,
  name : String,
  ty : Type,
) -> Unit raise XdrError {
  if self.schema.types.contains(name) || self.schema.constants.contains(name) {
    raise Invalid(self.offset(), "duplicate symbol: " + name)
  }
  self.schema.types[name] = ty
}

///|
pub fn Parser::add_constant(
  self : Parser,
  name : String,
  value : Int,
) -> Unit raise XdrError {
  if self.schema.types.contains(name) || self.schema.constants.contains(name) {
    raise Invalid(self.offset(), "duplicate symbol: " + name)
  }
  self.schema.constants[name] = value
}

///|
pub fn parse_schema(
  source : String,
  limits? : Limits = Limits::default(),
) -> Schema raise XdrError {
  let p = Parser::new(source, limits~)
  while p.peek() != "" {
    match p.take() {
      "const" => {
        let name = p.identifier()
        p.expect("=")
        let n = p.value()
        p.expect(";")
        p.add_constant(name, n)
      }
      "typedef" => {
        let f = p.declaration(0)
        p.expect(";")
        p.add_type(f.name, f.ty)
      }
      "enum" | "struct" | "union" as kind => {
        let name = p.identifier()
        let ty = p.compound(kind, 0)
        p.expect(";")
        p.add_type(name, ty)
      }
      _ => raise Invalid(p.offset(), "expected definition")
    }
  }
  p.schema.validate()
  p.schema
}
