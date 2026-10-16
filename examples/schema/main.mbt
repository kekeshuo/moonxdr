///|
fn main raise {
  let schema = @xdr.parse_schema(
    "const MAX = 8; enum State { READY=1, DONE=2 }; struct Sample { unsigned hyper sequence; string label<MAX>; double values<4>; State state; };",
  )
  let sample = @xdr.VStruct([
    ("sequence", @xdr.VUHyper(18446744073709551615UL)),
    ("label", @xdr.VString("sensor")),
    ("values", @xdr.VArray([@xdr.VDouble(1.25), @xdr.VDouble(-2.5)])),
    ("state", @xdr.VEnum(1)),
  ])
  let bytes = @xdr.encode(schema, "Sample", sample)
  let restored = @xdr.decode(schema, "Sample", bytes)
  assert_true(@xdr.encode(schema, "Sample", restored) == bytes)
  assert_eq(bytes.length(), 44)
  println(
    "schema workflow: exact unsigned64, bounded record and numeric array; 44 bytes",
  )
  println(@xdr.to_hex(bytes))
}
