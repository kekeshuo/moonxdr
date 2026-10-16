///|
test "record union and counted array have independent wire bytes" {
  let s = parse_schema(
    "struct Record { unsigned int id; string title<8>; int samples<4>; }; union Result switch(int tag) { case 1: Record record; default: void; };",
  )
  let value = VUnion(
    1,
    VStruct([
      ("id", VUInt(9U)),
      ("title", VString("ok")),
      ("samples", VArray([VInt(-1), VInt(2)])),
    ]),
  )
  let wire : Array[Byte] = [
    0, 0, 0, 1, 0, 0, 0, 9, 0, 0, 0, 2, 111, 107, 0, 0, 0, 0, 0, 2, 255, 255, 255,
    255, 0, 0, 0, 2,
  ]
  assert_true(encode(s, "Result", value) == wire)
  assert_true(encode(s, "Result", decode(s, "Result", wire)) == wire)
  assert_true(decode(s, "Result", [0, 0, 0, 8]) is VUnion(8, VVoid))
}

///|
test "linked recursive values round trip without flattening" {
  let s = parse_schema("struct Node { int value; Node *next; };")
  let value = VStruct([
    ("value", VInt(10)),
    (
      "next",
      VOptional(Some(VStruct([("value", VInt(20)), ("next", VOptional(None))]))),
    ),
  ])
  let bytes = encode(s, "Node", value)
  assert_true(bytes == [0, 0, 0, 10, 0, 0, 0, 1, 0, 0, 0, 20, 0, 0, 0, 0])
  assert_true(encode(s, "Node", decode(s, "Node", bytes)) == bytes)
}

///|
test "schema mismatches unrecognized enum and no-case unions fail" {
  let s = parse_schema(
    "enum E { A=1 }; typedef opaque Hash[3]; typedef int Pair[2]; union U switch(int tag){case 1: void;};",
  )
  assert_true(
    try {
      ignore(encode(s, "E", VEnum(2)))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(decode(s, "E", [0, 0, 0, 2]))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(encode(s, "Hash", VOpaque([1, 2])))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(encode(s, "Pair", VArray([VInt(1)])))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(decode(s, "U", [0, 0, 0, 2]))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(encode(s, "E", VInt(1)))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "aggregate count depth and every composite truncation rejected" {
  let limits : Limits = {
    max_bytes: 1024,
    max_items: 4,
    max_depth: 5,
    max_schema_tokens: 128,
  }
  let s = parse_schema("typedef int Items<10>;", limits~)
  assert_true(
    try {
      ignore(decode(s, "Items", [0, 0, 0, 5]))
      false
    } catch {
      _ => true
    },
  )
  let node = parse_schema("struct Node { int value; Node *next; };", limits~)
  let long : Array[Byte] = [
    0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 3, 0, 0, 0, 0,
  ]
  assert_true(
    try {
      ignore(decode(node, "Node", long))
      false
    } catch {
      _ => true
    },
  )
  let t = parse_schema("struct S { int a; string b<8>; };")
  let wire = encode(t, "S", VStruct([("a", VInt(1)), ("b", VString("abc"))]))
  for n = 0; n < wire.length(); n = n + 1 {
    assert_true(
      try {
        ignore(decode(t, "S", Array::makei(n, i => wire[i])))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_true(
    try {
      ignore(decode(t, "S", wire + [0]))
      false
    } catch {
      _ => true
    },
  )
}
