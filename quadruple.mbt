///|
/// RFC 4506 section 4.8 binary128, retained as two words on every backend.
/// This is a numeric wire type, not a Double approximation or a software arithmetic library.
pub(all) struct Quadruple {
  high : UInt64
  low : UInt64
} derive(Eq, Debug)

///|
pub(all) enum QuadrupleClass {
  Zero
  Subnormal
  Normal
  Infinite
  QuietNaN
  SignalingNaN
} derive(Eq, Debug)

///|
pub fn Quadruple::sign(self : Quadruple) -> Bool {
  self.high >> 63 != 0UL
}

///|
pub fn Quadruple::exponent(self : Quadruple) -> Int {
  ((self.high >> 48) & 0x7fffUL).to_int()
}

///|
pub fn Quadruple::fraction(self : Quadruple) -> (UInt64, UInt64) {
  (self.high & 0x0000ffffffffffffUL, self.low)
}

///|
pub fn Quadruple::classify(self : Quadruple) -> QuadrupleClass {
  let (hi, lo) = self.fraction()
  let empty = hi == 0UL && lo == 0UL
  match self.exponent() {
    0 => if empty { Zero } else { Subnormal }
    32767 =>
      if empty {
        Infinite
      } else if (hi & 0x0000800000000000UL) != 0UL {
        QuietNaN
      } else {
        SignalingNaN
      }
    _ => Normal
  }
}

///|
/// Exact widening from binary64. No arithmetic or conversion through decimal strings.
/// NaN sign, quiet/signaling bit and payload are widened without canonicalization.
pub fn Quadruple::from_double(value : Double) -> Quadruple {
  let bits = value.reinterpret_as_uint64()
  let sign = bits & 0x8000000000000000UL
  let exponent = ((bits >> 52) & 0x7ffUL).to_int()
  let fraction = bits & 0x000fffffffffffffUL
  if exponent == 0 {
    if fraction == 0UL {
      return { high: sign, low: 0UL, }
    }
    let mut p = 0
    let mut n = fraction
    while n > 1UL {
      n = n >> 1
      p += 1
    }
    let tail = fraction - (1UL << p)
    let shift = 112 - p
    let hi = if shift >= 64 {
      tail << (shift - 64)
    } else {
      tail >> (64 - shift)
    }
    let lo = if shift >= 64 { 0UL } else { tail << shift }
    return {
      high: sign | ((p - 1074 + 16383).to_uint64() << 48) | hi,
      low: lo,
    }
  }
  let e = if exponent == 2047 { 32767 } else { exponent + 15360 }
  { high: sign | (e.to_uint64() << 48) | (fraction >> 4), low: fraction << 60, }
}

///|
pub fn Quadruple::to_bytes(self : Quadruple) -> Array[Byte] {
  let out : Array[Byte] = []
  for word in [self.high, self.low] {
    for i = 7; i >= 0; i = i - 1 {
      out.push((word >> (i * 8)).to_byte())
    }
  }
  out
}

///|
pub fn Quadruple::to_hex(self : Quadruple) -> String {
  to_hex(self.to_bytes())
}

///|
pub fn Quadruple::from_hex(text : String) -> Quadruple raise XdrError {
  if text.length() != 32 {
    raise Invalid(0, "quadruple requires exactly 32 hexadecimal digits")
  }
  let r = Reader::new(from_hex(text))
  let q = r.read_quadruple()
  r.finish()
  q
}

///|
pub fn Writer::write_quadruple(
  self : Writer,
  value : Quadruple,
) -> Unit raise XdrError {
  self.write_raw(value.to_bytes())
}

///|
pub fn Reader::read_quadruple(self : Reader) -> Quadruple raise XdrError {
  if self.remaining() < 16 {
    raise Invalid(self.pos, "truncated quadruple")
  }
  { high: self.read_uhyper(), low: self.read_uhyper(), }
}

///|
pub extend Quadruple with Eq::{equal, not_equal}

///|
pub extend QuadrupleClass with Eq::{equal, not_equal}

///|
pub extend Quadruple with @debug.Debug::{to_repr}

///|
pub extend QuadrupleClass with @debug.Debug::{to_repr}
