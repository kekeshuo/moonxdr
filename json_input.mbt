///|
fn json_integer(json : Json) -> Int raise XdrError {
  check_json_integral(json)
  @json.from_json(json) catch {
    _ => raise Invalid(0, "expected signed 32-bit JSON integer")
  }
}

///|
fn json_input_at(
  schema : Schema,
  ty : Type,
  json : Json,
  budget : Budget,
  depth : Int,
) -> Value raise XdrError {
  budget.visit(depth, 0)
  match (ty, json) {
    (TRef(name), j) =>
      json_input_at(schema, schema.lookup(name), j, budget, depth + 1)
    (TVoid, Null) => VVoid
    (TInt, j) => VInt(json_integer(j))
    (TUInt, j) => {
      check_json_integral(j)
      let n : UInt = @json.from_json(j) catch {
        _ => raise Invalid(0, "expected unsigned 32-bit JSON integer")
      }
      VUInt(n)
    }
    (THyper, String(s)) => VHyper(parse_signed_decimal(s))
    (TUHyper, String(s)) => VUHyper(parse_unsigned_decimal(s))
    (TBool, True) => VBool(true)
    (TBool, False) => VBool(false)
    (TFloat, Number(n, ..)) => {
      if n.is_nan() || n.is_inf() || n.abs() > 3.4028234663852886e38 {
        raise Invalid(0, "JSON float out of finite range")
      }
      VFloat(Float::from_double(n))
    }
    (TDouble, Number(n, ..)) => {
      if n.is_nan() || n.is_inf() {
        raise Invalid(0, "JSON double out of finite range")
      }
      VDouble(n)
    }
    (TQuadruple, String(s)) => VQuadruple(Quadruple::from_hex(s))
    (TString(_), String(s)) => VString(s)
    (TOpaque(_, _), String(s)) => VOpaque(from_hex(s, limits=schema.limits))
    (TArray(inner, bound, variable), Array(items)) => {
      if items.length() > budget.left ||
        (variable && items.length().reinterpret_as_uint() > bound) ||
        (!variable && items.length().reinterpret_as_uint() != bound) {
        raise Invalid(0, "JSON array length limit")
      }
      let out : Array[Value] = []
      for item in items {
        out.push(json_input_at(schema, inner, item, budget, depth + 1))
      }
      VArray(out)
    }
    (TOptional(_), Null) => VOptional(None)
    (TOptional(inner), Object(object)) => {
      if object.length() != 1 {
        raise Invalid(0, "optional JSON requires one some member")
      }
      let item = match object.get("some") {
        Some(j) => j
        None => raise Invalid(0, "missing optional some member")
      }
      VOptional(Some(json_input_at(schema, inner, item, budget, depth + 1)))
    }
    (TEnum(labels), String(name)) => {
      for pair in labels {
        if pair.0 == name {
          return VEnum(pair.1)
        }
      }
      raise Invalid(0, "unknown enum name")
    }
    (TEnum(_), j) => VEnum(json_integer(j))
    (TStruct(fields), Object(object)) => {
      if object.length() != fields.length() {
        raise Invalid(0, "JSON record has missing or extra members")
      }
      let out : Array[(String, Value)] = []
      for field in fields {
        let item = match object.get(field.name) {
          Some(j) => j
          None => raise Invalid(0, "missing member: " + field.name)
        }
        out.push(
          (field.name, json_input_at(schema, field.ty, item, budget, depth + 1)),
        )
      }
      VStruct(out)
    }
    (TUnion(tag, arms, fallback), Object(object)) => {
      if object.length() != 2 {
        raise Invalid(0, "union JSON requires tag and value")
      }
      let n = match object.get("tag") {
        Some(j) => {
          check_json_integral(j)
          let n = match j {
            Number(n, ..) => n
            _ => raise Invalid(0, "expected union integer")
          }
          if n < -2147483648.0 || n > 4294967295.0 {
            raise Invalid(0, "union tag range")
          }
          n.to_int64()
        }
        None => raise Invalid(0, "missing union tag")
      }
      validate_tag(schema.resolve(tag), n)
      let item = match object.get("value") {
        Some(j) => j
        None => raise Invalid(0, "missing union value")
      }
      VUnion(
        n,
        json_input_at(
          schema,
          union_arm(arms, fallback, n),
          item,
          budget,
          depth + 1,
        ),
      )
    }
    _ => raise Invalid(0, "JSON shape does not match XDR type")
  }
}

///|
/// Local JSON convention, not an RFC-defined JSON wire format.
pub fn from_json(
  schema : Schema,
  type_name : String,
  json : Json,
) -> Value raise XdrError {
  let budget : Budget = {
    left: schema.limits.max_items,
    limits: schema.limits,
  }
  let value = json_input_at(schema, schema.lookup(type_name), json, budget, 0)
  // Reuse exact wire checks for bounds, ASCII, enum membership and fixed byte counts.
  ignore(encode(schema, type_name, value))
  value
}

///|
fn check_json_integral(json : Json) -> Unit raise XdrError {
  match json {
    Number(n, repr~) => {
      if n.is_nan() || n.is_inf() || n.floor() != n {
        raise Invalid(0, "expected integral JSON number")
      }
      // Plain decimal integer lexemes prevent a rounded fractional input becoming valid.
      if repr is Some(text) {
        if parse_signed_decimal(text).to_double() != n {
          raise Invalid(0, "inexact JSON integer")
        }
      }
    }
    _ => raise Invalid(0, "expected JSON number")
  }
}
