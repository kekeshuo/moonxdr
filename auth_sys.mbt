///|
/// AUTH_SYS is an unauthenticated assertion, not proof of identity.
pub(all) struct AuthSys {
  stamp : UInt
  machine : String
  uid : UInt
  gid : UInt
  groups : Array[UInt]
}

///|
pub fn AuthSys::to_auth(self : AuthSys) -> OpaqueAuth raise XdrError {
  if self.groups.length() > 16 {
    raise Invalid(0, "AUTH_SYS supplementary group limit")
  }
  let w = Writer::new()
  w.write_uint(self.stamp)
  w.write_string(self.machine, bound=255)
  w.write_uint(self.uid)
  w.write_uint(self.gid)
  w.write_uint(self.groups.length().reinterpret_as_uint())
  for group in self.groups {
    w.write_uint(group)
  }
  let body = w.bytes()
  if body.length() > 400 {
    raise Invalid(0, "AUTH_SYS body exceeds opaque_auth")
  }
  { flavor: 1U, body, }
}

///|
pub fn AuthSys::from_auth(auth : OpaqueAuth) -> AuthSys raise XdrError {
  if auth.flavor != 1U {
    raise Invalid(0, "expected AUTH_SYS flavor")
  }
  if auth.body.length() > 400 {
    raise Invalid(0, "AUTH_SYS body limit")
  }
  let r = Reader::new(auth.body)
  let stamp = r.read_uint()
  let machine = r.read_string(bound=255)
  let uid = r.read_uint()
  let gid = r.read_uint()
  let count = r.read_uint()
  if count > 16U {
    raise Invalid(r.position() - 4, "AUTH_SYS group limit")
  }
  let groups = []
  for i = 0; i < count.reinterpret_as_int(); i = i + 1 {
    groups.push(r.read_uint())
  }
  r.finish()
  { stamp, machine, uid, gid, groups, }
}
