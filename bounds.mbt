///|
pub suberror XdrError {
  Invalid(Int, String)
}

///|
/// All limits are per operation, never trusted from wire lengths.
pub(all) struct Limits {
  max_bytes : Int
  max_items : Int
  max_depth : Int
  max_schema_tokens : Int
}

///|
pub fn Limits::default() -> Limits {
  {
    max_bytes: 1048576,
    max_items: 65536,
    max_depth: 64,
    max_schema_tokens: 65536,
  }
}

///|
pub fn Limits::validate(self : Limits) -> Unit raise XdrError {
  if self.max_bytes < 4 ||
    self.max_bytes > 67108864 ||
    self.max_items < 1 ||
    self.max_items > 1048576 ||
    self.max_depth < 1 ||
    self.max_depth > 128 ||
    self.max_schema_tokens < 1 ||
    self.max_schema_tokens > 1048576 {
    raise Invalid(0, "invalid operation limits")
  }
}

///|
pub struct Reader {
  data : Array[Byte]
  mut pos : Int
  limits : Limits
}

///|
pub fn Reader::new(
  data : Array[Byte],
  limits? : Limits = Limits::default(),
) -> Reader raise XdrError {
  limits.validate()
  if data.length() > limits.max_bytes {
    raise Invalid(0, "input byte limit")
  }
  { data: data.copy(), pos: 0, limits, }
}

///|
pub fn Reader::position(self : Reader) -> Int {
  self.pos
}

///|
pub fn Reader::remaining(self : Reader) -> Int {
  self.data.length() - self.pos
}

///|
pub fn Reader::read_raw(
  self : Reader,
  count : Int,
) -> Array[Byte] raise XdrError {
  if count < 0 || count > self.remaining() {
    raise Invalid(self.pos, "truncated input")
  }
  let out = Array::makei(count, i => self.data[self.pos + i])
  self.pos += count
  out
}

///|
pub fn Reader::read_uint(self : Reader) -> UInt raise XdrError {
  let b = self.read_raw(4)
  (b[0].to_uint() << 24) |
  (b[1].to_uint() << 16) |
  (b[2].to_uint() << 8) |
  b[3].to_uint()
}

///|
pub fn Reader::read_int(self : Reader) -> Int raise XdrError {
  self.read_uint().reinterpret_as_int()
}

///|
pub fn Reader::finish(self : Reader) -> Unit raise XdrError {
  if self.remaining() != 0 {
    raise Invalid(self.pos, "trailing bytes")
  }
}
