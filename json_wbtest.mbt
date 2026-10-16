///|
test "JSON interchange preserves exact hyper extrema and nested optionals" {
  let s = parse_schema(
    "typedef int *OptionalInt; struct S { hyper a; unsigned hyper b; OptionalInt *nested; opaque data<4>; };",
  )
  let input = @json.parse(
    "{\"a\":\"-9223372036854775808\",\"b\":\"18446744073709551615\",\"nested\":{\"some\":null},\"data\":\"00ffab\"}",
  )
  let value = from_json(s, "S", input)
  let wire = encode(s, "S", value)
  let back = to_json(s, "S", decode(s, "S", wire))
  assert_true(back == input)
  assert_true(encode(s, "S", from_json(s, "S", back)) == wire)
}

///|
test "JSON enums union shapes field names and bounds enforced" {
  let s = parse_schema(
    "enum E{A=1}; union U switch(E e){case A: string label<3>;};",
  )
  let j = @json.parse("{\"tag\":1,\"value\":\"ok\"}")
  assert_true(to_json(s, "U", from_json(s, "U", j)) == j)
  assert_true(from_json(s, "E", @json.parse("\"A\"")) is VEnum(1))
  for
    text in [
      "{\"tag\":1}", "{\"tag\":2,\"value\":\"ok\"}", "{\"tag\":1,\"value\":\"long\"}",
      "{\"tag\":1,\"value\":\"é\"}",
    ] {
    assert_true(
      try {
        ignore(from_json(s, "U", @json.parse(text)))
        false
      } catch {
        _ => true
      },
    )
  }
}

///|
test "decimal overflow and JSON rounding are rejected rather than repaired" {
  assert_eq(
    parse_unsigned_decimal("18446744073709551615"),
    0xffffffffffffffffUL,
  )
  assert_eq(
    parse_signed_decimal("-9223372036854775808"),
    -9223372036854775807L - 1L,
  )
  for text in ["18446744073709551616", "-1", "+1", " 1", ""] {
    assert_true(
      try {
        ignore(parse_unsigned_decimal(text))
        false
      } catch {
        _ => true
      },
    )
  }
  for text in ["9223372036854775808", "-9223372036854775809"] {
    assert_true(
      try {
        ignore(parse_signed_decimal(text))
        false
      } catch {
        _ => true
      },
    )
  }
  let s = parse_schema(
    "typedef hyper H; typedef unsigned int U; typedef int I;",
  )
  assert_true(
    try {
      ignore(from_json(s, "H", @json.parse("9007199254740993")))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(from_json(s, "I", @json.parse("1.5")))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(from_json(s, "U", @json.parse("-1")))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "JSON finite-only policy hex and record rejection" {
  let s = parse_schema("typedef double D; struct R{int x;};")
  assert_true(
    try {
      ignore(
        to_json(s, "D", VDouble(0x7ff0000000000000UL.reinterpret_as_double())),
      )
      false
    } catch {
      _ => true
    },
  )
  for text in ["{}", "{\"x\":1,\"extra\":2}", "{\"y\":1}"] {
    assert_true(
      try {
        ignore(from_json(s, "R", @json.parse(text)))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_eq(to_hex(from_hex("00Ff80")), "00ff80")
  for text in ["0", "xx", "0 "] {
    assert_true(
      try {
        ignore(from_hex(text))
        false
      } catch {
        _ => true
      },
    )
  }
}
