///|
fn rejects_schema(source : String) -> Bool {
  try {
    ignore(parse_schema(source))
    false
  } catch {
    _ => true
  }
}

///|
fn rejects_wire(schema : Schema, name : String, bytes : Array[Byte]) -> Bool {
  try {
    ignore(decode(schema, name, bytes))
    false
  } catch {
    _ => true
  }
}

///|
test "unsigned max literal union has exact expected network bytes" {
  let s = parse_schema(
    "union Max switch (unsigned int tag) { case 4294967295: int result; default: void; };",
  )
  let value = VUnion(4294967295L, VInt(7))
  let wire = encode(s, "Max", value)
  assert_eq(to_hex(wire), "ffffffff00000007")
  assert_true(decode(s, "Max", wire) is VUnion(4294967295L, VInt(7)))
  assert_eq(
    to_hex(encode(s, "Max", decode(s, "Max", wire))),
    "ffffffff00000007",
  )
  assert_eq(
    to_json(s, "Max", value).stringify(),
    "{\"tag\":4294967295,\"value\":7}",
  )
  assert_true(
    from_json(s, "Max", @json.parse("{\"tag\":4294967295,\"value\":7}"))
    is VUnion(4294967295L, VInt(7)),
  )
}

///|
test "unsigned case constants agree across decimal hex octal aliases and typedefs" {
  for literal in ["4294967295", "0xffffffff", "037777777777"] {
    let s = parse_schema(
      "const MAX=" +
      literal +
      "; typedef unsigned int Tag; union U switch(Tag t) { case MAX: void; };",
    )
    assert_eq(s.constant("MAX").unwrap().to_string(), "4294967295")
    assert_eq(to_hex(encode(s, "U", VUnion(4294967295L, VVoid))), "ffffffff")
  }
}

///|
test "union labels are checked in discriminant mathematical domain not bit patterns" {
  for
    source in [
      "union U switch(unsigned int t) { case -1: void; };", "union U switch(unsigned int t) { case 4294967296: void; };",
      "union U switch(int t) { case 4294967295: void; };", "union U switch(int t) { case -2147483649: void; };",
      "union U switch(bool t) { case 4294967295: void; };", "union U switch(unsigned int t) { case 0xffffffff: void; case 4294967295: void; };",
      "enum E { OUT=2147483648 };",
    ] {
    assert_true(rejects_schema(source))
  }
  let s = parse_schema(
    "union U switch(int t) { case -2147483648: void; case 2147483647: void; };",
  )
  assert_eq(to_hex(encode(s, "U", VUnion(-2147483648L, VVoid))), "80000000")
  assert_eq(to_hex(encode(s, "U", VUnion(2147483647L, VVoid))), "7fffffff")
}

///|
test "union default and invalid runtime domains remain checked" {
  let s = parse_schema(
    "union U switch(unsigned int t) { case 4294967295: int n; default: void; };",
  )
  assert_true(decode(s, "U", [128, 0, 0, 0]) is VUnion(2147483648L, VVoid))
  for tag in [-1L, 4294967296L] {
    assert_true(
      try {
        ignore(encode(s, "U", VUnion(tag, VVoid)))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_true(rejects_wire(s, "U", [255, 255, 255, 255]))
  let no_default = parse_schema(
    "union U switch(unsigned int t) { case 4294967295: void; };",
  )
  assert_true(rejects_wire(no_default, "U", [0, 0, 0, 0]))
}

///|
test "constants are exact beyond 64 bits and narrowed only at typed uses" {
  let text = "340282366920938463463374607431768211455"
  let s = parse_schema(
    "const HUGE=" + text + "; const NEG=-0x100000000000000000000000000000000;",
  )
  assert_eq(s.constant("HUGE").unwrap().to_string(), text)
  assert_eq(
    s.constant("NEG").unwrap().to_string(),
    "-340282366920938463463374607431768211456",
  )
  assert_true(rejects_schema("const BIG=" + text + "; typedef int A[BIG];"))
  for text in ["09", "0x", "-", "0xgg", "123abc"] {
    assert_true(
      try {
        ignore(parse_integer_constant(text))
        false
      } catch {
        _ => true
      },
    )
  }
}

///|
test "all declaration bounds preserve unsigned max separately from budgets" {
  let s = parse_schema(
    "typedef string S<>; typedef opaque O<>; typedef int A<>; typedef opaque F[4294967295]; typedef int G[0xffffffff]; typedef string B<4294967295>;",
  )
  assert_true(s.lookup("S") is TString(4294967295U))
  assert_true(s.lookup("O") is TOpaque(4294967295U, true))
  assert_true(s.lookup("A") is TArray(TInt, 4294967295U, true))
  assert_true(s.lookup("F") is TOpaque(4294967295U, false))
  assert_true(s.lookup("G") is TArray(TInt, 4294967295U, false))
  assert_eq(to_hex(encode(s, "B", VString("ok"))), "000000026f6b0000")
  for name in ["S", "O", "A", "F", "G"] {
    assert_true(rejects_wire(s, name, [255, 255, 255, 255]))
  }
  for
    source in [
      "typedef int A[4294967296];", "typedef string S<-1>;", "typedef int A[];",
    ] {
    assert_true(rejects_schema(source))
  }
}

///|
test "changing operation limits never changes schema declared bound" {
  let limits : Limits = {
    max_bytes: 64,
    max_items: 2,
    max_depth: 8,
    max_schema_tokens: 64,
  }
  let s = parse_schema("typedef int A<>; typedef opaque O<>;", limits~)
  assert_true(s.lookup("A") is TArray(TInt, 4294967295U, true))
  assert_eq(to_hex(encode(s, "A", VArray([VInt(3)]))), "0000000100000003")
  assert_true(
    try {
      ignore(encode(s, "A", VArray([VInt(1), VInt(2)])))
      false
    } catch {
      _ => true
    },
  )
  assert_true(rejects_wire(s, "O", [0, 0, 0, 65]))
}

///|
test "union declaration member scopes and standalone void are checked" {
  for
    source in [
      "union U switch(int tag) { case 0: int tag; };", "union U switch(int tag) { case 0: int repeated; default: int repeated; };",
      "typedef void NamedVoid;", "typedef int _bad;", "enum E { A=0, };",
    ] {
    assert_true(rejects_schema(source))
  }
  let s = parse_schema(
    "union U switch(int tag) { case 0: struct { int tag; } nested; default: void; };",
  )
  assert_eq(
    to_hex(encode(s, "U", VUnion(0L, VStruct([("tag", VInt(3))])))),
    "0000000000000003",
  )
}

///|
test "XDR whitespace comments and legal identifier underbars" {
  let s = parse_schema("/* comment */\u000btypedef\u000cunsigned int Item_id;")
  assert_true(s.lookup("Item_id") is TUInt)
  assert_eq(to_hex(encode(s, "Item_id", VUInt(4294967295U))), "ffffffff")
}

///|
test "RFC section 7 published file wire vector through independently named schema" {
  let s = parse_schema(
    "enum K { TXT=0, RAW=1, BIN=2 }; union Info switch(K kind) { case TXT: void; case RAW: string maker<255>; case BIN: string runtime<255>; }; struct Entry { string name<255>; Info info; string account<32>; opaque content<65535>; };",
  )
  let v = VStruct([
    ("name", VString("sillyprog")),
    ("info", VUnion(2L, VString("lisp"))),
    ("account", VString("john")),
    ("content", VOpaque([40, 113, 117, 105, 116, 41])),
  ])
  let expected = "0000000973696c6c7970726f6700000000000002000000046c697370000000046a6f686e000000062871756974290000"
  assert_eq(to_hex(encode(s, "Entry", v)), expected)
  assert_eq(
    to_hex(encode(s, "Entry", decode(s, "Entry", from_hex(expected)))),
    expected,
  )
}

///|
test "optional data is wire equivalent to bool discriminated union" {
  let s = parse_schema(
    "typedef int *Maybe; union U switch(bool present) { case FALSE: void; case TRUE: int data; };",
  )
  assert_true(
    encode(s, "Maybe", VOptional(None)) == encode(s, "U", VUnion(0L, VVoid)),
  )
  assert_true(
    encode(s, "Maybe", VOptional(Some(VInt(-17)))) ==
    encode(s, "U", VUnion(1L, VInt(-17))),
  )
  assert_true(rejects_wire(s, "Maybe", [0, 0, 0, 2]))
  assert_true(rejects_wire(s, "U", [0, 0, 0, 2]))
}

///|
test "embedded ASCII nul is preserved with length not a C terminator" {
  let s = parse_schema("typedef string S<>;")
  let value = VString("a\u0000b")
  assert_eq(to_hex(encode(s, "S", value)), "0000000361006200")
  assert_true(
    decode(s, "S", from_hex("0000000361006200")) is VString("a\u0000b"),
  )
  assert_true(rejects_wire(s, "S", from_hex("0000000361006201")))
}
