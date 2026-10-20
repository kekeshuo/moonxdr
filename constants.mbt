///|
/// Parse RFC 4506 decimal/octal/hex integer literals exactly, without a machine-word cap.
/// The 4096-character ceiling is an operation budget, not an integer type restriction.
pub fn parse_integer_constant(
  text : String,
  offset? : Int = 0,
) -> @bigint.BigInt raise XdrError {
  let cs = text.to_array()
  if cs.length() > 4096 {
    raise Invalid(offset, "constant literal resource limit")
  }
  let negative = cs.length() > 0 && cs[0] == '-'
  let mut i = if negative { 1 } else { 0 }
  if i == cs.length() {
    raise Invalid(offset, "missing integer digits")
  }
  let mut radix = 10
  if i + 1 < cs.length() && cs[i] == '0' {
    if cs[i + 1] == 'x' || cs[i + 1] == 'X' {
      radix = 16
      i += 2
    } else {
      radix = 8
    }
  }
  if i == cs.length() {
    raise Invalid(offset, "missing hexadecimal digits")
  }
  let digits = StringBuilder()
  while i < cs.length() {
    let c = cs[i]
    let d = if c >= '0' && c <= '9' {
      c.to_int() - 48
    } else if c >= 'a' && c <= 'f' {
      c.to_int() - 87
    } else if c >= 'A' && c <= 'F' {
      c.to_int() - 55
    } else {
      raise Invalid(offset + i, "invalid integer digit")
    }
    if d >= radix {
      raise Invalid(offset + i, "invalid integer digit")
    }
    digits.write_char(c)
    i += 1
  }
  let n = @bigint.BigInt::from_string(digits.to_string(), radix~)
  if negative {
    -n
  } else {
    n
  }
}

///|
fn constant_i32(n : @bigint.BigInt, offset : Int) -> Int raise XdrError {
  if n.compare_int64(-2147483648L) < 0 || n.compare_int64(2147483647L) > 0 {
    raise Invalid(offset, "signed 32-bit value out of range")
  }
  n.to_int()
}

///|
fn constant_u32(n : @bigint.BigInt, offset : Int) -> UInt raise XdrError {
  if n.compare_int(0) < 0 || n.compare_uint(4294967295U) > 0 {
    raise Invalid(offset, "unsigned 32-bit value out of range")
  }
  n.to_uint()
}

///|
fn constant_tag(n : @bigint.BigInt, offset : Int) -> Int64 raise XdrError {
  if n.compare_int64(-2147483648L) < 0 || n.compare_int64(4294967295L) > 0 {
    raise Invalid(offset, "union case outside signed/unsigned 32-bit range")
  }
  n.to_int64()
}
