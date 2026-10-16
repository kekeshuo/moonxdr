///|
fn json_output_at(
  value : Value,
  budget : Budget,
  depth : Int,
) -> Json raise XdrError {
  budget.visit(depth, 0)
  match value {
    VVoid => Json::null()
    VInt(n) | VEnum(n) => n.to_json()
    VUInt(n) => n.to_json()
    VHyper(n) => Json::string(n.to_string())
    VUHyper(n) => Json::string(n.to_string())
    VBool(b) => b.to_json()
    VFloat(f) => {
      let n = f.to_double()
      if n.is_nan() || n.is_inf() {
        raise Invalid(0, "nonfinite float has no JSON representation")
      }
      n.to_json()
    }
    VDouble(n) => {
      if n.is_nan() || n.is_inf() {
        raise Invalid(0, "nonfinite double has no JSON representation")
      }
      n.to_json()
    }
    VString(s) => Json::string(s)
    VOpaque(bytes) => Json::string(to_hex(bytes))
    VArray(items) => {
      let out : Array[Json] = []
      for item in items {
        out.push(json_output_at(item, budget, depth + 1))
      }
      Json::array(out)
    }
    VOptional(None) => Json::null()
    VOptional(Some(item)) =>
      Json::object({ "some": json_output_at(item, budget, depth + 1) })
    VStruct(fields) => {
      let out : Map[String, Json] = Map([])
      for pair in fields {
        if out.contains(pair.0) {
          raise Invalid(0, "duplicate record member")
        }
        out[pair.0] = json_output_at(pair.1, budget, depth + 1)
      }
      Json::object(out)
    }
    VUnion(tag, item) =>
      Json::object({
        "tag": tag.to_json(),
        "value": json_output_at(item, budget, depth + 1),
      })
  }
}

///|
/// Binary validation precedes JSON output, including ASCII, collection and total byte limits.
pub fn to_json(
  schema : Schema,
  type_name : String,
  value : Value,
) -> Json raise XdrError {
  ignore(encode(schema, type_name, value))
  let budget : Budget = {
    left: schema.limits.max_items,
    limits: schema.limits,
  }
  json_output_at(value, budget, 0)
}
