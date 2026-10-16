///|
test "compile RFC shaped enum record and union declarations" {
  let s = parse_schema(
    "const MAX=0x10; enum Kind { A=0, B=1 }; struct Packet { Kind kind; string name<MAX>; opaque hash[3]; }; union Reply switch (Kind kind) { case A: void; case B: Packet packet; default: int error; };",
  )
  assert_eq(s.constant("MAX"), Some(16))
  assert_true(s.type_names() == ["Kind", "Reply", "Packet"])
  assert_true(s.lookup("Reply") is TUnion(TRef("Kind"), _, Some(TInt)))
}

///|
test "recursive pointer aliases variable and fixed arrays compile" {
  let s = parse_schema(
    "/*nodes*/ struct Node { int value; Node *next; }; typedef Node Tree; typedef unsigned hyper IDs<20>; typedef int Matrix[6]; // end",
  )
  assert_true(s.resolve(s.lookup("Tree")) is TStruct(_))
  assert_true(s.lookup("IDs") is TArray(TUHyper, 20, true))
  assert_true(s.lookup("Matrix") is TArray(TInt, 6, false))
}

///|
test "invalid schema semantics cannot become executable" {
  for
    source in [
      "typedef Missing Item;", "typedef B A; typedef A B;", "struct Loop { Loop value; };",
      "struct S { int x; int x; };", "enum E { A=1, B=1 };", "const A=1; const A=2;",
      "union U switch (double d) { default: void; };", "union U switch (bool b) { case 2: void; };",
      "union U switch (int d) { case 1: void; case 1: int x; };", "union U switch (int d) { default: void; default: void; };",
      "typedef int Bad[-1];", "struct S { void member; };", "enum E { A=0 }; union U switch(E e) { case 1: void; };",
      "/* unterminated", "#include <x>", "typedef int x",
    ] {
    assert_true(
      try {
        ignore(parse_schema(source))
        false
      } catch {
        _ => true
      },
    )
  }
}

///|
test "constant syntax and schema resource boundaries" {
  assert_eq(parse_constant_number("077"), 63)
  assert_eq(parse_constant_number("-0x80000000"), -2147483647 - 1)
  for source in ["2147483648", "-2147483649", "09", "0x", "-", "Z"] {
    assert_true(
      try {
        ignore(parse_constant_number(source))
        false
      } catch {
        _ => true
      },
    )
  }
  let limits : Limits = {
    max_bytes: 1024,
    max_items: 3,
    max_depth: 3,
    max_schema_tokens: 8,
  }
  assert_true(
    try {
      ignore(parse_schema("struct S { int a; int b; };", limits~))
      false
    } catch {
      _ => true
    },
  )
  let s = parse_schema("typedef int X<>;")
  assert_true(s.lookup("X") is TArray(TInt, 65536, true))
}
