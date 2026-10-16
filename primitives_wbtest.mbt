///|
test "RFC big endian integer vectors and exact hyper values" {
  let w = Writer::new()
  w.write_int(-2)
  w.write_uint(0xffffffffU)
  w.write_hyper(-9223372036854775807L - 1L)
  w.write_uhyper(0xffffffffffffffffUL)
  assert_true(
    w.bytes() ==
    [
      255, 255, 255, 254, 255, 255, 255, 255, 128, 0, 0, 0, 0, 0, 0, 0, 255, 255,
      255, 255, 255, 255, 255, 255,
    ],
  )
  let r = Reader::new(w.bytes())
  assert_eq(r.read_int(), -2)
  assert_eq(r.read_uint(), 0xffffffffU)
  assert_eq(r.read_hyper(), -9223372036854775807L - 1L)
  assert_eq(r.read_uhyper(), 0xffffffffffffffffUL)
  r.finish()
}

///|
test "IEEE signed zero and noncanonical NaN payloads preserved" {
  for bits in [0U, 0x80000000U, 0x7fc01234U, 0xff800000U] {
    let w = Writer::new()
    w.write_float(Float::reinterpret_from_uint(bits))
    assert_eq(Reader::new(w.bytes()).read_float().reinterpret_as_uint(), bits)
  }
  for bits in [0UL, 0x8000000000000000UL, 0x7ff8123456789012UL] {
    let w = Writer::new()
    w.write_double(bits.reinterpret_as_double())
    assert_eq(
      Reader::new(w.bytes()).read_double().reinterpret_as_uint64(),
      bits,
    )
  }
}

///|
test "opaque alignment and independent string wire vector" {
  let w = Writer::new()
  w.write_string("abc")
  w.write_fixed([1, 2, 3, 4, 5])
  assert_true(w.bytes() == [0, 0, 0, 3, 97, 98, 99, 0, 1, 2, 3, 4, 5, 0, 0, 0])
  let r = Reader::new(w.bytes())
  assert_eq(r.read_string(), "abc")
  assert_true(r.read_fixed(5) == [1, 2, 3, 4, 5])
  r.finish()
}

///|
test "hostile lengths padding booleans and non ASCII fail" {
  assert_true(
    try {
      ignore(Reader::new([0, 0, 0, 2]).read_bool())
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(Reader::new([255, 255, 255, 255]).read_opaque())
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(Reader::new([0, 0, 0, 1, 65, 1, 0, 0]).read_string())
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      Writer::new().write_string("中文")
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      Reader::new([0]).finish()
      false
    } catch {
      _ => true
    },
  )
}

///|
test "every scalar truncation and ownership isolation" {
  for n = 0; n < 4; n = n + 1 {
    assert_true(
      try {
        ignore(Reader::new(Array::make(n, 0)).read_uint())
        false
      } catch {
        _ => true
      },
    )
  }
  let data : Array[Byte] = [0, 0, 0, 1]
  let r = Reader::new(data)
  data[3] = 99
  assert_eq(r.read_uint(), 1U)
  let w = Writer::new()
  w.write_bool(true)
  let copy = w.bytes()
  copy[3] = 0
  assert_eq(Reader::new(w.bytes()).read_bool(), true)
}
