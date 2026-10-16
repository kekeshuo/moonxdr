///|
/// Wire authentication only; these bytes do not establish a trusted identity.
pub(all) struct OpaqueAuth {
  flavor : UInt
  body : Array[Byte]
}

///|
pub fn OpaqueAuth::none() -> OpaqueAuth {
  { flavor: 0U, body: [], }
}

///|
pub fn Writer::write_auth(
  self : Writer,
  auth : OpaqueAuth,
) -> Unit raise XdrError {
  self.write_uint(auth.flavor)
  self.write_opaque(auth.body, bound=400)
}

///|
pub fn Reader::read_auth(self : Reader) -> OpaqueAuth raise XdrError {
  let flavor = self.read_uint()
  let body = self.read_opaque(bound=400)
  { flavor, body, }
}

///|
pub(all) struct RpcCall {
  xid : UInt
  program : UInt
  version : UInt
  procedure : UInt
  credential : OpaqueAuth
  verifier : OpaqueAuth
  arguments : Array[Byte]
}

///|
pub fn encode_call(
  call : RpcCall,
  limits? : Limits = Limits::default(),
) -> Array[Byte] raise XdrError {
  let w = Writer::new(limits~)
  if call.arguments.length() % 4 != 0 {
    raise Invalid(0, "RPC arguments must be XDR aligned")
  }
  w.write_uint(call.xid)
  w.write_uint(0U)
  w.write_uint(2U)
  w.write_uint(call.program)
  w.write_uint(call.version)
  w.write_uint(call.procedure)
  w.write_auth(call.credential)
  w.write_auth(call.verifier)
  w.write_raw(call.arguments)
  w.bytes()
}

///|
pub fn decode_call(
  bytes : Array[Byte],
  limits? : Limits = Limits::default(),
) -> RpcCall raise XdrError {
  let r = Reader::new(bytes, limits~)
  let xid = r.read_uint()
  if r.read_uint() != 0U {
    raise Invalid(4, "expected RPC CALL")
  }
  if r.read_uint() != 2U {
    raise Invalid(8, "unsupported RPC protocol version")
  }
  let program = r.read_uint()
  let version = r.read_uint()
  let procedure = r.read_uint()
  let credential = r.read_auth()
  let verifier = r.read_auth()
  if r.remaining() % 4 != 0 {
    raise Invalid(r.position(), "unaligned RPC arguments")
  }
  let arguments = r.read_raw(r.remaining())
  { xid, program, version, procedure, credential, verifier, arguments, }
}
