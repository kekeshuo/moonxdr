///|
pub struct Writer {
  data : Array[Byte]
  limits : Limits
}

///|
pub fn Writer::new(
  limits? : Limits = Limits::default(),
) -> Writer raise XdrError {
  limits.validate()
  { data: [], limits, }
}

///|
pub fn Writer::bytes(self : Writer) -> Array[Byte] {
  self.data.copy()
}

///|
pub fn Writer::length(self : Writer) -> Int {
  self.data.length()
}

///|
pub fn Writer::write_raw(
  self : Writer,
  bytes : Array[Byte],
) -> Unit raise XdrError {
  if bytes.length() > self.limits.max_bytes - self.data.length() {
    raise Invalid(self.data.length(), "output byte limit")
  }
  self.data.append(bytes)
}

///|
pub fn Writer::write_uint(self : Writer, n : UInt) -> Unit raise XdrError {
  self.write_raw([
    (n >> 24).to_byte(),
    (n >> 16).to_byte(),
    (n >> 8).to_byte(),
    n.to_byte(),
  ])
}

///|
pub fn Writer::write_int(self : Writer, n : Int) -> Unit raise XdrError {
  self.write_uint(n.reinterpret_as_uint())
}

///|
pub fn Writer::write_uhyper(self : Writer, n : UInt64) -> Unit raise XdrError {
  self.write_uint((n >> 32).to_uint())
  self.write_uint(n.to_uint())
}

///|
pub fn Writer::write_hyper(self : Writer, n : Int64) -> Unit raise XdrError {
  self.write_uhyper(n.reinterpret_as_uint64())
}

///|
pub fn Writer::write_bool(self : Writer, b : Bool) -> Unit raise XdrError {
  self.write_uint(if b { 1U } else { 0U })
}

///|
pub fn Writer::write_float(self : Writer, f : Float) -> Unit raise XdrError {
  self.write_uint(f.reinterpret_as_uint())
}

///|
pub fn Writer::write_double(self : Writer, d : Double) -> Unit raise XdrError {
  self.write_uhyper(d.reinterpret_as_uint64())
}

///|
pub fn Reader::read_uhyper(self : Reader) -> UInt64 raise XdrError {
  let hi = self.read_uint().to_uint64()
  let lo = self.read_uint().to_uint64()
  (hi << 32) | lo
}

///|
pub fn Reader::read_hyper(self : Reader) -> Int64 raise XdrError {
  self.read_uhyper().reinterpret_as_int64()
}

///|
pub fn Reader::read_bool(self : Reader) -> Bool raise XdrError {
  match self.read_uint() {
    0U => false
    1U => true
    _ => raise Invalid(self.pos - 4, "boolean must be zero or one")
  }
}

///|
pub fn Reader::read_float(self : Reader) -> Float raise XdrError {
  Float::reinterpret_from_uint(self.read_uint())
}

///|
pub fn Reader::read_double(self : Reader) -> Double raise XdrError {
  self.read_uhyper().reinterpret_as_double()
}
