///|
test "record streams survive every split and one-byte feeds" {
  let payload = from_hex("00000001000000020000000300000004")
  let framed = fragment_record(payload, 3)
  for split = 0; split <= framed.length(); split = split + 1 {
    let d = RecordDecoder::new()
    let a = d.feed(Array::makei(split, i => framed[i]))
    let b = d.feed(
      Array::makei(framed.length() - split, i => framed[split + i]),
    )
    assert_eq(a.length() + b.length(), 1)
    let result = if a.is_empty() { b[0] } else { a[0] }
    assert_true(result == payload)
    d.finish()
  }
  let stream = framed.copy()
  for b in fragment_record([], 4) {
    stream.push(b)
  }
  for b in framed {
    stream.push(b)
  }
  let d = RecordDecoder::new()
  let results : Array[Array[Byte]] = []
  for byte in stream {
    for record in d.feed([byte]) {
      results.push(record)
    }
  }
  d.finish()
  assert_eq(results.length(), 3)
  assert_true(
    results[0] == payload && results[1].is_empty() && results[2] == payload,
  )
  assert_eq(to_hex(fragment_record([1, 2, 3], 2)), "0000000201028000000103")
}

///|
test "record EOF errors poison state and final empty fragments work" {
  let framed = fragment_record([1, 2, 3, 4], 2)
  for n = 1; n < framed.length(); n = n + 1 {
    let d = RecordDecoder::new()
    ignore(d.feed(Array::makei(n, i => framed[i])))
    assert_true(
      try {
        d.finish()
        false
      } catch {
        _ => true
      },
    )
    assert_true(
      try {
        ignore(d.feed(framed))
        false
      } catch {
        _ => true
      },
    )
  }
  let d = RecordDecoder::new()
  let out = d.feed([0, 0, 0, 0, 128, 0, 0, 0])
  assert_eq(out.length(), 1)
  assert_true(out[0].is_empty())
  out[0].push(1)
  assert_true(d.feed([128, 0, 0, 0])[0].is_empty())
  d.finish()
}

///|
test "record hostile sizes aggregate counts and header-only attacks" {
  let limits : Limits = {
    max_bytes: 16,
    max_items: 2,
    max_depth: 4,
    max_schema_tokens: 16,
  }
  let d = RecordDecoder::new(limits~)
  assert_true(
    try {
      ignore(d.feed([255, 255, 255, 255]))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(d.feed([]))
      false
    } catch {
      _ => true
    },
  )
  let many = RecordDecoder::new(limits~)
  assert_true(
    try {
      ignore(many.feed([0, 0, 0, 0, 0, 0, 0, 0, 128, 0, 0, 0]))
      false
    } catch {
      _ => true
    },
  )
  let outputs = RecordDecoder::new(limits~)
  assert_true(
    try {
      ignore(outputs.feed([128, 0, 0, 0, 128, 0, 0, 0, 128, 0, 0, 0]))
      false
    } catch {
      _ => true
    },
  )
  let total = RecordDecoder::new(limits~)
  ignore(total.feed([0, 0, 0, 12]))
  ignore(total.feed(Array::make(12, 0)))
  assert_true(
    try {
      ignore(total.feed([128, 0, 0, 8]))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(fragment_record(Array::make(16, 0), 16, limits~))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(fragment_record([], 0))
      false
    } catch {
      _ => true
    },
  )
}
