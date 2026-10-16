///|
pub(all) enum AcceptStatus {
  Success(Array[Byte])
  ProgramUnavailable
  ProgramMismatch(UInt, UInt)
  ProcedureUnavailable
  GarbageArguments
  SystemError
}

///|
pub(all) enum RejectStatus {
  RpcMismatch(UInt, UInt)
  AuthError(UInt)
}

///|
pub(all) enum ReplyBody {
  Accepted(OpaqueAuth, AcceptStatus)
  Rejected(RejectStatus)
}

///|
pub(all) struct RpcReply {
  xid : UInt
  body : ReplyBody
}

///|
fn Writer::write_versions(
  self : Writer,
  low : UInt,
  high : UInt,
) -> Unit raise XdrError {
  if low > high {
    raise Invalid(self.length(), "reversed RPC version range")
  }
  self.write_uint(low)
  self.write_uint(high)
}

///|
fn Reader::read_versions(self : Reader) -> (UInt, UInt) raise XdrError {
  let low = self.read_uint()
  let high = self.read_uint()
  if low > high {
    raise Invalid(self.position() - 8, "reversed RPC version range")
  }
  (low, high)
}

///|
pub fn encode_reply(
  reply : RpcReply,
  limits? : Limits = Limits::default(),
) -> Array[Byte] raise XdrError {
  let w = Writer::new(limits~)
  w.write_uint(reply.xid)
  w.write_uint(1U)
  match reply.body {
    Accepted(verifier, status) => {
      w.write_uint(0U)
      w.write_auth(verifier)
      match status {
        Success(result) => {
          if result.length() % 4 != 0 {
            raise Invalid(w.length(), "RPC result must be XDR aligned")
          }
          w.write_uint(0U)
          w.write_raw(result)
        }
        ProgramUnavailable => w.write_uint(1U)
        ProgramMismatch(low, high) => {
          w.write_uint(2U)
          w.write_versions(low, high)
        }
        ProcedureUnavailable => w.write_uint(3U)
        GarbageArguments => w.write_uint(4U)
        SystemError => w.write_uint(5U)
      }
    }
    Rejected(reason) => {
      w.write_uint(1U)
      match reason {
        RpcMismatch(low, high) => {
          w.write_uint(0U)
          w.write_versions(low, high)
        }
        AuthError(status) => {
          w.write_uint(1U)
          w.write_uint(status)
        }
      }
    }
  }
  w.bytes()
}

///|
pub fn decode_reply(
  bytes : Array[Byte],
  limits? : Limits = Limits::default(),
) -> RpcReply raise XdrError {
  let r = Reader::new(bytes, limits~)
  let xid = r.read_uint()
  if r.read_uint() != 1U {
    raise Invalid(4, "expected RPC REPLY")
  }
  let body = match r.read_uint() {
    0U => {
      let verifier = r.read_auth()
      let status = match r.read_uint() {
        0U => {
          if r.remaining() % 4 != 0 {
            raise Invalid(r.position(), "unaligned RPC result")
          }
          Success(r.read_raw(r.remaining()))
        }
        1U => ProgramUnavailable
        2U => {
          let (low, high) = r.read_versions()
          ProgramMismatch(low, high)
        }
        3U => ProcedureUnavailable
        4U => GarbageArguments
        5U => SystemError
        _ => raise Invalid(r.position() - 4, "unknown RPC accept status")
      }
      Accepted(verifier, status)
    }
    1U => {
      let reason = match r.read_uint() {
        0U => {
          let (low, high) = r.read_versions()
          RpcMismatch(low, high)
        }
        1U => AuthError(r.read_uint())
        _ => raise Invalid(r.position() - 4, "unknown RPC reject status")
      }
      Rejected(reason)
    }
    _ => raise Invalid(8, "unknown RPC reply status")
  }
  r.finish()
  { xid, body, }
}
