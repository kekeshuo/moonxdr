///|
fn main raise {
  let schema = @xdr.parse_schema(
    "struct Fixture { hyper minimum; unsigned hyper maximum; opaque digest[3]; int *choice; };",
  )
  let source = "{\"minimum\":\"-9223372036854775808\",\"maximum\":\"18446744073709551615\",\"digest\":\"00abff\",\"choice\":{\"some\":7}}"
  let value = @xdr.from_json(schema, "Fixture", @json.parse(source))
  let hex = @xdr.to_hex(@xdr.encode(schema, "Fixture", value))
  assert_eq(hex, "8000000000000000ffffffffffffffff00abff000000000100000007")
  let restored = @xdr.decode(schema, "Fixture", @xdr.from_hex(hex))
  let output = @xdr.to_json(schema, "Fixture", restored)
  assert_true(
    @xdr.encode(schema, "Fixture", @xdr.from_json(schema, "Fixture", output)) ==
    @xdr.from_hex(hex),
  )
  println(
    "interchange workflow: JSON -> checked typed value -> XDR hex -> exact JSON",
  )
  println(hex)
  println(output.stringify())
}
