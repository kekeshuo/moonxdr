///|
fn main raise {
  let schema = @xdr.parse_schema(
    "typedef quadruple Q; union Measurement switch (unsigned int tag) { case 4294967295: Q reading; default: void; };",
  )
  let number = @xdr.Quadruple::from_hex("3fff0000000000000000000000000000")
  let value = @xdr.VUnion(4294967295L, @xdr.VQuadruple(number))
  let wire = @xdr.encode(schema, "Measurement", value)
  assert_eq(@xdr.to_hex(wire), "ffffffff3fff0000000000000000000000000000")
  let restored = @xdr.decode(schema, "Measurement", wire)
  assert_true(@xdr.encode(schema, "Measurement", restored) == wire)
  let json = @xdr.to_json(schema, "Measurement", restored)
  let from_json = @xdr.from_json(schema, "Measurement", json)
  assert_true(@xdr.encode(schema, "Measurement", from_json) == wire)
  println("binary128 + unsigned UINT32_MAX union: " + @xdr.to_hex(wire))
  println(json.stringify())
}
