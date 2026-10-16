///|
pub fn Writer::write_fixed(
  self : Writer,
  bytes : Array[Byte],
) -> Unit raise XdrError {
  let padding = (4 - bytes.length() % 4) % 4
  if bytes.length() > self.limits.max_bytes - self.length() - padding {
    raise Invalid(self.length(), "opaque byte limit")
  }
  self.write_raw(bytes)
  self.write_raw(Array::make(padding, 0))
}

///|
pub fn Reader::read_fixed(
  self : Reader,
  length : Int,
) -> Array[Byte] raise XdrError {
  if length < 0 || length > self.limits.max_bytes {
    raise Invalid(self.pos, "opaque length limit")
  }
  let padding = (4 - length % 4) % 4
  if length > self.remaining() - padding {
    raise Invalid(self.pos, "truncated opaque")
  }
  let out = self.read_raw(length)
  for b in self.read_raw(padding) {
    if b != 0 {
      raise Invalid(self.pos - padding, "nonzero XDR padding")
    }
  }
  out
}

///|
pub fn Writer::write_opaque(
  self : Writer,
  bytes : Array[Byte],
  bound? : Int = 1048576,
) -> Unit raise XdrError {
  if bound < 0 || bytes.length() > bound {
    raise Invalid(self.length(), "opaque bound exceeded")
  }
  self.write_uint(bytes.length().reinterpret_as_uint())
  self.write_fixed(bytes)
}

///|
pub fn Reader::read_length(self : Reader, bound : Int) -> Int raise XdrError {
  let length = self.read_uint()
  if bound < 0 || length > bound.reinterpret_as_uint() {
    raise Invalid(self.pos - 4, "length bound exceeded")
  }
  length.reinterpret_as_int()
}

///|
pub fn Reader::read_opaque(
  self : Reader,
  bound? : Int = 1048576,
) -> Array[Byte] raise XdrError {
  let n = self.read_length(bound)
  self.read_fixed(n)
}

///|
/// RFC 4506 strings are ASCII; arbitrary bytes use opaque instead.
pub fn Writer::write_string(
  self : Writer,
  text : String,
  bound? : Int = 1048576,
) -> Unit raise XdrError {
  let bytes : Array[Byte] = []
  for c in text.iter() {
    if c.to_int() > 127 {
      raise Invalid(self.length(), "XDR string must be ASCII")
    }
    bytes.push(c.to_int().to_byte())
  }
  for b in bytes {
    if b > 127 {
      raise Invalid(self.length(), "XDR string must be ASCII")
    }
  }
  self.write_opaque(bytes, bound~)
}

///|
pub fn Reader::read_string(
  self : Reader,
  bound? : Int = 1048576,
) -> String raise XdrError {
  let bytes = self.read_opaque(bound~)
  let out = StringBuilder()
  for b in bytes {
    if b > 127 {
      raise Invalid(self.pos - bytes.length(), "XDR string must be ASCII")
    }
    out.write_char(b.to_char())
  }
  out.to_string()
}
