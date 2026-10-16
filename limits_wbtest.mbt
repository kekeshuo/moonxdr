///|
test "schema nesting and finite validation have explicit bounded work" {
  let limits : Limits = {
    max_bytes: 8192,
    max_items: 1024,
    max_depth: 8,
    max_schema_tokens: 256,
  }
  let mut text = "typedef "
  for i = 0; i < 10; i = i + 1 {
    text += "struct { "
  }
  text += "int x;"
  for i = 0; i < 10; i = i + 1 {
    text += " } x;"
  }
  assert_true(
    try {
      ignore(parse_schema(text, limits~))
      false
    } catch {
      _ => true
    },
  )
  let work = Budget::{ left: 1, limits, }
  let ty = TStruct([{ name: "x", ty: TInt, }])
  assert_true(
    try {
      ignore(can_terminate(ty, Map([]), work, 0))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(parse_schema("struct A { B b; }; struct B { A a; };"))
      false
    } catch {
      _ => true
    },
  )
  let good = parse_schema(
    "struct A { B children<2>; }; struct B { A *parent; };",
  )
  let bytes = encode(good, "A", VStruct([("children", VArray([]))]))
  assert_true(bytes == [0, 0, 0, 0])
}

///|
test "opaque prefix fuzz always errors rather than accepting excess bytes" {
  for length = 0; length <= 32; length = length + 1 {
    let bytes = Array::makei(length, i => ((i * 73 + length) % 256).to_byte())
    let w = Writer::new()
    w.write_opaque(bytes)
    let wire = w.bytes()
    assert_true(Reader::new(wire).read_opaque() == bytes)
    for n = 0; n < wire.length(); n = n + 1 {
      assert_true(
        try {
          ignore(Reader::new(Array::makei(n, i => wire[i])).read_opaque())
          false
        } catch {
          _ => true
        },
      )
    }
  }
}
