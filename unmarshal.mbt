///|
fn decode_at(
  schema : Schema,
  ty : Type,
  r : Reader,
  budget : Budget,
  depth : Int,
) -> Value raise XdrError {
  budget.visit(depth, r.position())
  match ty {
    TRef(name) => decode_at(schema, schema.lookup(name), r, budget, depth + 1)
    TVoid => VVoid
    TInt => VInt(r.read_int())
    TUInt => VUInt(r.read_uint())
    THyper => VHyper(r.read_hyper())
    TUHyper => VUHyper(r.read_uhyper())
    TBool => VBool(r.read_bool())
    TFloat => VFloat(r.read_float())
    TDouble => VDouble(r.read_double())
    TQuadruple => VQuadruple(r.read_quadruple())
    TString(bound) => VString(r.read_string(bound~))
    TOpaque(bound, variable) =>
      VOpaque(
        if variable {
          r.read_opaque(bound~)
        } else {
          r.read_fixed(
            checked_count(bound, schema.limits.max_bytes, r.position()),
          )
        },
      )
    TArray(inner, bound, variable) => {
      let n = if variable {
        r.read_length(bound)
      } else {
        checked_count(bound, budget.left, r.position())
      }
      if n > budget.left {
        raise Invalid(r.position(), "aggregate value item limit")
      }
      let out : Array[Value] = []
      for i = 0; i < n; i = i + 1 {
        out.push(decode_at(schema, inner, r, budget, depth + 1))
      }
      VArray(out)
    }
    TOptional(inner) =>
      if r.read_bool() {
        VOptional(Some(decode_at(schema, inner, r, budget, depth + 1)))
      } else {
        VOptional(None)
      }
    TEnum(labels) => {
      let n = r.read_int()
      validate_tag(TEnum(labels), n.to_int64())
      VEnum(n)
    }
    TStruct(fields) => {
      let out : Array[(String, Value)] = []
      for field in fields {
        out.push(
          (field.name, decode_at(schema, field.ty, r, budget, depth + 1)),
        )
      }
      VStruct(out)
    }
    TUnion(tag, arms, fallback) => {
      let resolved = schema.resolve(tag)
      let bits = r.read_uint()
      let n = if resolved is TUInt {
        bits.to_int64()
      } else {
        bits.reinterpret_as_int().to_int64()
      }
      validate_tag(resolved, n)
      VUnion(
        n,
        decode_at(schema, union_arm(arms, fallback, n), r, budget, depth + 1),
      )
    }
  }
}

///|
/// Decode exactly one datum; trailing bytes are rejected, not silently discarded.
pub fn decode(
  schema : Schema,
  type_name : String,
  bytes : Array[Byte],
) -> Value raise XdrError {
  let r = Reader::new(bytes, limits=schema.limits)
  let budget : Budget = {
    left: schema.limits.max_items,
    limits: schema.limits,
  }
  let value = decode_at(schema, schema.lookup(type_name), r, budget, 0)
  r.finish()
  value
}
