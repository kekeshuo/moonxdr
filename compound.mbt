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
    let seen_values : Map[Int, Bool] = Map([])
    while self.peek() != "}" {
      let name = self.identifier()
      self.expect("=")
      let literal = self.value()
      let value = constant_i32(literal, self.offset())
      if seen_values.contains(value) {
        raise Invalid(self.offset(), "duplicate enum value")
      }
      seen_values[value] = true
      self.add_constant(name, literal)
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
    let seen_fields : Map[String, Bool] = Map([])
    while self.peek() != "}" {
      let field = self.declaration(depth + 1)
      self.expect(";")
      if seen_fields.contains(field.name) {
        raise Invalid(self.offset(), "duplicate struct member")
      }
      seen_fields[field.name] = true
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
  let seen : Map[Int64, Bool] = Map([])
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
      let labels : Array[Int64] = []
      while self.peek() == "case" {
        self.expect("case")
        let label = constant_tag(self.value(), self.offset())
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
