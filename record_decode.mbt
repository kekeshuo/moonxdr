///|
/// Incremental, owned record assembly. A malformed feed permanently poisons
/// this decoder. feed returns records only on success; discard the stream on error.
pub struct RecordDecoder {
  limits : Limits
  record : Array[Byte]
  mut marker : UInt
  mut header_bytes : Int
  mut body_left : Int
  mut last : Bool
  mut fragments : Int
  mut poisoned : Bool
}

///|
pub fn RecordDecoder::new(
  limits? : Limits = Limits::default(),
) -> RecordDecoder raise XdrError {
  limits.validate()
  {
    limits,
    record: [],
    marker: 0U,
    header_bytes: 0,
    body_left: 0,
    last: false,
    fragments: 0,
    poisoned: false,
  }
}

///|
fn RecordDecoder::complete(
  self : RecordDecoder,
  records : Array[Array[Byte]],
) -> Unit raise XdrError {
  if self.last {
    if records.length() >= self.limits.max_items {
      raise Invalid(0, "completed record count limit")
    }
    records.push(self.record.copy())
    self.record.clear()
    self.fragments = 0
  }
  self.header_bytes = 0
  self.marker = 0U
  self.last = false
}

///|
fn RecordDecoder::consume(
  self : RecordDecoder,
  chunk : Array[Byte],
) -> Array[Array[Byte]] raise XdrError {
  if chunk.length() > self.limits.max_bytes {
    raise Invalid(0, "feed byte limit")
  }
  let records = []
  for byte in chunk {
    if self.header_bytes < 4 {
      self.marker = (self.marker << 8) | byte.to_uint()
      self.header_bytes += 1
      if self.header_bytes == 4 {
        self.fragments += 1
        if self.fragments > self.limits.max_items {
          raise Invalid(0, "fragment count limit")
        }
        let size = self.marker & 0x7fffffffU
        if size >
          (self.limits.max_bytes - self.record.length()).reinterpret_as_uint() {
          raise Invalid(0, "assembled record byte limit")
        }
        self.body_left = size.reinterpret_as_int()
        self.last = (self.marker & 0x80000000U) != 0U
        if self.body_left == 0 {
          self.complete(records)
        }
      }
    } else {
      self.record.push(byte)
      self.body_left -= 1
      if self.body_left == 0 {
        self.complete(records)
      }
    }
  }
  records
}

///|
pub fn RecordDecoder::feed(
  self : RecordDecoder,
  chunk : Array[Byte],
) -> Array[Array[Byte]] raise XdrError {
  if self.poisoned {
    raise Invalid(0, "record decoder is poisoned")
  }
  errdefer {
    self.poisoned = true
    self.record.clear()
  }
  self.consume(chunk)
}

///|
/// End of transport: incomplete headers, bodies and non-final records are errors.
pub fn RecordDecoder::finish(self : RecordDecoder) -> Unit raise XdrError {
  if self.poisoned {
    raise Invalid(0, "record decoder is poisoned")
  }
  if self.header_bytes != 0 || self.fragments != 0 {
    self.poisoned = true
    self.record.clear()
    raise Invalid(0, "truncated record stream")
  }
}
