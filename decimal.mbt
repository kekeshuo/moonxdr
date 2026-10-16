///|
/// Exact decimal conversion used for JSON hyper integers; never passes through Double.
pub fn parse_unsigned_decimal(text : String) -> UInt64 raise XdrError {
  if text.is_empty() {
    raise Invalid(0, "empty decimal integer")
  }
  let mut value = 0UL
  for i, c in text.to_array() {
    if c < '0' || c > '9' {
      raise Invalid(i, "expected decimal digit")
    }
    let digit = (c.to_int() - 48).to_uint64()
    if value > (0xffffffffffffffffUL - digit) / 10UL {
      raise Invalid(i, "unsigned hyper overflow")
    }
    value = value * 10UL + digit
  }
  value
}

///|
pub fn parse_signed_decimal(text : String) -> Int64 raise XdrError {
  let cs = text.to_array()
  let negative = cs.length() > 0 && cs[0] == '-'
  let digits = if negative {
    String::from_array(cs.exact_view(start=1))
  } else {
    text
  }
  let value = parse_unsigned_decimal(digits)
  let bound = if negative { 0x8000000000000000UL } else { 0x7fffffffffffffffUL }
  if value > bound {
    raise Invalid(0, "signed hyper overflow")
  }
  (if negative { 0UL - value } else { value }).reinterpret_as_int64()
}

///|
pub fn to_hex(bytes : Array[Byte]) -> String {
  let out = StringBuilder()
  let digits = "0123456789abcdef".to_array()
  for b in bytes {
    out.write_char(digits[b.to_int() >> 4])
    out.write_char(digits[b.to_int() & 15])
  }
  out.to_string()
}

///|
pub fn from_hex(
  text : String,
  limits? : Limits = Limits::default(),
) -> Array[Byte] raise XdrError {
  limits.validate()
  if text.length() % 2 != 0 || text.length() / 2 > limits.max_bytes {
    raise Invalid(0, "invalid hex length")
  }
  let cs = text.to_array()
  let out : Array[Byte] = []
  let mut high = 0
  for i, c in cs {
    let n = if c >= '0' && c <= '9' {
      c.to_int() - 48
    } else if c >= 'a' && c <= 'f' {
      c.to_int() - 87
    } else if c >= 'A' && c <= 'F' {
      c.to_int() - 55
    } else {
      raise Invalid(i, "invalid hex digit")
    }
    if i % 2 == 0 {
      high = n
    } else {
      out.push((high * 16 + n).to_byte())
    }
  }
  out
}
