///|
pub fn Parser::arm_type(self : Parser, depth : Int) -> Type raise XdrError {
  if self.peek() == "void" {
    self.expect("void")
    self.expect(";")
    TVoid
  } else {
    let field = self.declaration(depth)
    self.expect(";")
    field.ty
  }
}

///|
pub fn Parser::compound(
  self : Parser,
  kind : String,
  depth : Int,
) -> Type raise XdrError {
  if depth > self.schema.limits.max_depth {
    raise Invalid(self.offset(), "schema nesting limit")
  }
  if kind == "enum" {
    self.expect("{")
    let values : Array[(String, Int)] = []
    while self.peek() != "}" {
      let name = self.identifier()
      self.expect("=")
      let value = self.value()
      for pair in values {
        if pair.1 == value {
          raise Invalid(self.offset(), "duplicate enum value")
        }
      }
      self.add_constant(name, value)
      values.push((name, value))
      if self.peek() != "," {
        break
      }
      self.expect(",")
    }
    self.expect("}")
    if values.is_empty() {
      raise Invalid(self.offset(), "empty enum")
    }
    return TEnum(values)
  }
  if kind == "struct" {
    self.expect("{")
    let fields : Array[Field] = []
    while self.peek() != "}" {
      let field = self.declaration(depth + 1)
      self.expect(";")
      for old in fields {
        if old.name == field.name {
          raise Invalid(self.offset(), "duplicate struct member")
        }
      }
      fields.push(field)
    }
    self.expect("}")
    if fields.is_empty() {
      raise Invalid(self.offset(), "empty struct")
    }
    return TStruct(fields)
  }
  if kind != "union" {
    raise Invalid(self.offset(), "unknown compound type")
  }
  self.expect("switch")
  self.expect("(")
  let discriminant = self.declaration(depth + 1)
  self.expect(")")
  self.expect("{")
  let arms : Array[Arm] = []
  let seen : Map[Int, Bool] = Map([])
  let mut fallback : Type? = None
  while self.peek() != "}" {
    if self.peek() == "default" {
      if fallback is Some(_) {
        raise Invalid(self.offset(), "duplicate default arm")
      }
      self.expect("default")
      self.expect(":")
      fallback = Some(self.arm_type(depth + 1))
    } else {
      let labels : Array[Int] = []
      while self.peek() == "case" {
        self.expect("case")
        let label = self.value()
        self.expect(":")
        if seen.contains(label) {
          raise Invalid(self.offset(), "duplicate union case")
        }
        seen[label] = true
        labels.push(label)
      }
      if labels.is_empty() {
        raise Invalid(self.offset(), "expected union case or default")
      }
      arms.push({ labels, ty: self.arm_type(depth + 1), })
    }
  }
  self.expect("}")
  if arms.is_empty() && fallback is None {
    raise Invalid(self.offset(), "empty union")
  }
  TUnion(discriminant.ty, arms, fallback)
}
