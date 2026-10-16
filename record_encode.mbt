///|
/// RFC 5531 record markers; fragment size need not be XDR-word aligned.
/// The returned framed buffer, including headers, must fit max_bytes.
pub fn fragment_record(
  record : Array[Byte],
  fragment_size : Int,
  limits? : Limits = Limits::default(),
) -> Array[Byte] raise XdrError {
  limits.validate()
  if fragment_size < 1 || fragment_size > limits.max_bytes {
    raise Invalid(0, "invalid fragment size")
  }
  if record.length() > limits.max_bytes {
    raise Invalid(0, "record byte limit")
  }
  let count = if record.is_empty() {
    1
  } else {
    (record.length() - 1) / fragment_size + 1
  }
  if count > limits.max_items ||
    count > (limits.max_bytes - record.length()) / 4 {
    raise Invalid(0, "framed record budget")
  }
  let w = Writer::new(limits~)
  let mut offset = 0
  for i = 0; i < count; i = i + 1 {
    let size = if fragment_size < record.length() - offset {
      fragment_size
    } else {
      record.length() - offset
    }
    let last = i == count - 1
    let marker = size.reinterpret_as_uint() |
      (if last { 0x80000000U } else { 0U })
    w.write_uint(marker)
    w.write_raw(Array::makei(size, j => record[offset + j]))
    offset += size
  }
  w.bytes()
}
