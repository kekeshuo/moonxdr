///|
priv struct Budget {
  mut left : Int
  limits : Limits
}

///|
fn Budget::visit(
  self : Budget,
  depth : Int,
  offset : Int,
) -> Unit raise XdrError {
  if depth > self.limits.max_depth {
    raise Invalid(offset, "value depth limit")
  }
  if self.left <= 0 {
    raise Invalid(offset, "aggregate value item limit")
  }
  self.left -= 1
}

///|
fn encode_at(
  schema : Schema,
  ty : Type,
  value : Value,
  w : Writer,
  budget : Budget,
  depth : Int,
) -> Unit raise XdrError {
  budget.visit(depth, w.length())
  match (ty, value) {
    (TRef(name), v) =>
      encode_at(schema, schema.lookup(name), v, w, budget, depth + 1)
    (TVoid, VVoid) => ()
    (TInt, VInt(n)) => w.write_int(n)
    (TUInt, VUInt(n)) => w.write_uint(n)
    (THyper, VHyper(n)) => w.write_hyper(n)
    (TUHyper, VUHyper(n)) => w.write_uhyper(n)
    (TBool, VBool(n)) => w.write_bool(n)
    (TFloat, VFloat(n)) => w.write_float(n)
    (TDouble, VDouble(n)) => w.write_double(n)
    (TQuadruple, VQuadruple(n)) => w.write_quadruple(n)
    (TString(bound), VString(s)) => w.write_string(s, bound~)
    (TOpaque(bound, variable), VOpaque(b)) =>
      if variable {
        w.write_opaque(b, bound~)
      } else {
        if b.length().reinterpret_as_uint() != bound {
          raise Invalid(w.length(), "fixed opaque length mismatch")
        }
        w.write_fixed(b)
      }
    (TArray(inner, bound, variable), VArray(values)) => {
      if (variable && values.length().reinterpret_as_uint() > bound) ||
        (!variable && values.length().reinterpret_as_uint() != bound) {
        raise Invalid(w.length(), "array length mismatch")
      }
      if values.length() > budget.left {
        raise Invalid(w.length(), "aggregate value item limit")
      }
      if variable {
        w.write_uint(values.length().reinterpret_as_uint())
      }
      for item in values {
        encode_at(schema, inner, item, w, budget, depth + 1)
      }
    }
    (TOptional(inner), VOptional(opt)) => {
      w.write_bool(opt is Some(_))
      if opt is Some(v) {
        encode_at(schema, inner, v, w, budget, depth + 1)
      }
    }
    (TEnum(labels), VEnum(n)) => {
      validate_tag(TEnum(labels), n.to_int64())
      w.write_int(n)
    }
    (TStruct(fields), VStruct(values)) => {
      if values.length() != fields.length() {
        raise Invalid(w.length(), "record field count mismatch")
      }
      for i, field in fields {
        if values[i].0 != field.name {
          raise Invalid(
            w.length(),
            "record field name or order mismatch: " + field.name,
          )
        }
        encode_at(schema, field.ty, values[i].1, w, budget, depth + 1)
      }
    }
    (TUnion(tag, arms, fallback), VUnion(n, v)) => {
      validate_tag(schema.resolve(tag), n)
      w.write_uint(n.to_int().reinterpret_as_uint())
      encode_at(schema, union_arm(arms, fallback, n), v, w, budget, depth + 1)
    }
    _ => raise Invalid(w.length(), "value does not match schema type")
  }
}

///|
pub fn encode(
  schema : Schema,
  type_name : String,
  value : Value,
) -> Array[Byte] raise XdrError {
  let w = Writer::new(limits=schema.limits)
  let budget : Budget = {
    left: schema.limits.max_items,
    limits: schema.limits,
  }
  encode_at(schema, schema.lookup(type_name), value, w, budget, 0)
  w.bytes()
}
