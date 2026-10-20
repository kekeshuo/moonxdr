///|
test "quadruple standard classes and all 112 fraction bits are retained" {
  let cases : Array[(String, QuadrupleClass, Bool)] = [
    ("00000000000000000000000000000000", Zero, false),
    ("80000000000000000000000000000000", Zero, true),
    ("3fff0000000000000000000000000000", Normal, false),
    ("bfff0000000000000000000000000000", Normal, true),
    ("00000000000000000000000000000001", Subnormal, false),
    ("0000ffffffffffffffffffffffffffff", Subnormal, false),
    ("00010000000000000000000000000000", Normal, false),
    ("7ffeffffffffffffffffffffffffffff", Normal, false),
    ("7fff0000000000000000000000000000", Infinite, false),
    ("ffff0000000000000000000000000000", Infinite, true),
    ("7fff8000000000000000000000000001", QuietNaN, false),
    ("7fff0000000000000000000000000001", SignalingNaN, false),
  ]
  for item in cases {
    let q = Quadruple::from_hex(item.0)
    assert_eq(q.to_hex(), item.0)
    assert_eq(q.classify(), item.1)
    assert_eq(q.sign(), item.2)
    let w = Writer::new()
    w.write_quadruple(q)
    assert_eq(to_hex(w.bytes()), item.0)
    assert_eq(Reader::new(w.bytes()).read_quadruple(), q)
  }
}

///|
test "quadruple nested schema JSON union array optional pipeline" {
  let s = parse_schema(
    "typedef quadruple Q; struct Sample { Q values<4>; Q *optional; }; union U switch(unsigned int tag) { case 4294967295: Sample sample; default: void; };",
  )
  let input = @json.parse(
    "{\"tag\":4294967295,\"value\":{\"values\":[\"3fff0000000000000000000000000000\",\"00000000000000000000000000000001\"],\"optional\":{\"some\":\"7fff8000000000000000000000000001\"}}}",
  )
  let v = from_json(s, "U", input)
  let bytes = encode(s, "U", v)
  assert_eq(
    to_hex(bytes),
    "ffffffff000000023fff000000000000000000000000000000000000000000000000000000000001000000017fff8000000000000000000000000001",
  )
  assert_eq(to_json(s, "U", decode(s, "U", bytes)), input)
}

///|
test "quadruple truncation malformed hex and wrong JSON type are rejected" {
  let s = parse_schema("typedef quadruple Q;")
  for n = 0; n < 16; n = n + 1 {
    assert_true(rejects_wire(s, "Q", Array::make(n, 0)))
  }
  assert_true(rejects_wire(s, "Q", Array::make(17, 0)))
  for
    text in [
      "", "3fff", "3fff000000000000000000000000000z", "3fff00000000000000000000000000000",
    ] {
    assert_true(
      try {
        ignore(Quadruple::from_hex(text))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_true(
    try {
      ignore(from_json(s, "Q", (1).to_json()))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "quadruple exact binary64 widening known values includes least subnormal" {
  for
    item in [
      (0UL, "00000000000000000000000000000000"),
      (0x8000000000000000UL, "80000000000000000000000000000000"),
      (0x3ff0000000000000UL, "3fff0000000000000000000000000000"),
      (0x0000000000000001UL, "3bcd0000000000000000000000000000"),
      (0x7ff0000000000000UL, "7fff0000000000000000000000000000"),
      (0x7ff8000000000001UL, "7fff8000000000001000000000000000"),
    ] {
    assert_eq(
      Quadruple::from_double(item.0.reinterpret_as_double()).to_hex(),
      item.1,
    )
  }
}
