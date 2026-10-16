///|
test "RPC call exact header and AUTH_SYS asserted identity" {
  let auth = AuthSys::{
    stamp: 7U,
    machine: "host",
    uid: 1000U,
    gid: 100U,
    groups: [2U, 3U],
  }.to_auth()
  let identity = AuthSys::from_auth(auth)
  assert_eq(identity.machine, "host")
  assert_true(identity.groups == [2U, 3U])
  let call : RpcCall = {
    xid: 9U,
    program: 100003U,
    version: 3U,
    procedure: 1U,
    credential: auth,
    verifier: OpaqueAuth::none(),
    arguments: [0, 0, 0, 8],
  }
  let bytes = encode_call(call)
  assert_eq(
    to_hex(Array::makei(24, i => bytes[i])),
    "000000090000000000000002000186a30000000300000001",
  )
  let back = decode_call(bytes)
  assert_eq(back.xid, 9U)
  assert_true(back.arguments == [0, 0, 0, 8])
  assert_true(encode_call(back) == bytes)
  assert_true(
    try {
      ignore(AuthSys::from_auth(OpaqueAuth::none()))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(
        AuthSys::{
          stamp: 0U,
          machine: "m",
          uid: 0U,
          gid: 0U,
          groups: Array::make(17, 0U),
        }.to_auth(),
      )
      false
    } catch {
      _ => true
    },
  )
  let bad = bytes.copy()
  bad[11] = 3
  assert_true(
    try {
      ignore(decode_call(bad))
      false
    } catch {
      _ => true
    },
  )
  for n = 0; n < bytes.length() - 4; n = n + 1 {
    assert_true(
      try {
        ignore(decode_call(Array::makei(n, i => bytes[i])))
        false
      } catch {
        _ => true
      },
    )
  }
}

///|
test "every RPC accepted and denied branch is preserved" {
  let bodies : Array[ReplyBody] = [
    Accepted(OpaqueAuth::none(), Success([0, 0, 0, 1])),
    Accepted(OpaqueAuth::none(), ProgramUnavailable),
    Accepted(OpaqueAuth::none(), ProgramMismatch(1U, 4U)),
    Accepted(OpaqueAuth::none(), ProcedureUnavailable),
    Accepted(OpaqueAuth::none(), GarbageArguments),
    Accepted(OpaqueAuth::none(), SystemError),
    Rejected(RpcMismatch(2U, 2U)),
    Rejected(AuthError(7U)),
  ]
  for body in bodies {
    let bytes = encode_reply({ xid: 99U, body, })
    assert_true(encode_reply(decode_reply(bytes)) == bytes)
  }
  assert_eq(
    to_hex(encode_reply({ xid: 1U, body: Rejected(AuthError(1U)), })),
    "0000000100000001000000010000000100000001",
  )
  assert_true(
    try {
      ignore(encode_reply({ xid: 0U, body: Rejected(RpcMismatch(9U, 1U)), }))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(decode_reply(from_hex("000000010000000100000003")))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(
        decode_reply(
          from_hex("000000010000000100000000000000000000000000000006"),
        ),
      )
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(decode_reply(from_hex("0000000100000001000000010000000200000000")))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "RPC envelope bounds and strict non-success consumption" {
  assert_true(
    try {
      ignore(
        encode_call({
          xid: 0U,
          program: 0U,
          version: 0U,
          procedure: 0U,
          credential: { flavor: 1U, body: Array::make(401, 0), },
          verifier: OpaqueAuth::none(),
          arguments: [],
        }),
      )
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(
        encode_reply({
          xid: 0U,
          body: Accepted(OpaqueAuth::none(), Success([0])),
        }),
      )
      false
    } catch {
      _ => true
    },
  )
  let bytes = encode_reply({
    xid: 1U,
    body: Accepted(OpaqueAuth::none(), SystemError),
  })
  bytes.push(0)
  assert_true(
    try {
      ignore(decode_reply(bytes))
      false
    } catch {
      _ => true
    },
  )
  let auth = AuthSys::{ stamp: 0U, machine: "", uid: 0U, gid: 0U, groups: [], }.to_auth()
  auth.body.push(0)
  assert_true(
    try {
      ignore(AuthSys::from_auth(auth))
      false
    } catch {
      _ => true
    },
  )
}
