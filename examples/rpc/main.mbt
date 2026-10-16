///|
fn main raise {
  let schema = @xdr.parse_schema(
    "struct Request { unsigned int key; }; struct Response { string text<32>; };",
  )
  let arguments = @xdr.encode(
    schema,
    "Request",
    @xdr.VStruct([("key", @xdr.VUInt(42U))]),
  )
  let credential = @xdr.AuthSys::{
    stamp: 1U,
    machine: "fixture",
    uid: 1000U,
    gid: 1000U,
    groups: [1000U],
  }.to_auth()
  let wire = @xdr.encode_call({
    xid: 17U,
    program: 0x20000001U,
    version: 1U,
    procedure: 1U,
    credential,
    verifier: @xdr.OpaqueAuth::none(),
    arguments,
  })
  let framed = @xdr.fragment_record(wire, 7)
  let decoder = @xdr.RecordDecoder::new()
  let records : Array[Array[Byte]] = []
  for byte in framed {
    for record in decoder.feed([byte]) {
      records.push(record)
    }
  }
  decoder.finish()
  assert_eq(records.length(), 1)
  let call = @xdr.decode_call(records[0])
  assert_eq(@xdr.AuthSys::from_auth(call.credential).machine, "fixture")
  assert_true(
    @xdr.decode(schema, "Request", call.arguments)
    is @xdr.VStruct([("key", @xdr.VUInt(42U))]),
  )
  let result = @xdr.encode(
    schema,
    "Response",
    @xdr.VStruct([("text", @xdr.VString("found"))]),
  )
  let reply = @xdr.decode_reply(
    @xdr.encode_reply({
      xid: call.xid,
      body: @xdr.Accepted(@xdr.OpaqueAuth::none(), @xdr.Success(result)),
    }),
  )
  assert_eq(reply.xid, call.xid)
  match reply.body {
    @xdr.Accepted(_, @xdr.Success(bytes)) =>
      assert_true(
        @xdr.decode(schema, "Response", bytes)
        is @xdr.VStruct([("text", @xdr.VString("found"))]),
      )
    _ => abort("unexpected reply")
  }
  println(
    "rpc workflow: asserted AUTH_SYS, schema payload, 7-byte fragments, bytewise reconstruction and reply",
  )
}
