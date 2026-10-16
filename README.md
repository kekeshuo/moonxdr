# MoonXDR

Pure MoonBit schema-driven XDR interchange and ONC RPCv2 wire tools.

Module: `kekeshuo/moonxdr@0.1.0` · MIT · no external runtime dependencies beyond MoonBit core.

## Why

XDR defines more than big-endian integers. Applications also need declaration parsing,
bounded arrays, discriminated unions, recursive optional values, exact 64-bit numbers,
strict padding and procedure payload composition. MoonXDR supplies these as one reusable
interpreter instead of generating C stubs or providing an NFS-specific data reader.
It is an original implementation of the supported subset of RFC 4506 / RFC 5531,
not a port of rpcgen, CPython or go-xdr. It is **not a full RPC client/server**.

## Install and import

```sh
moon add kekeshuo/moonxdr@0.1.0
```

Add `"kekeshuo/moonxdr" @xdr` to your package's imports. A calling function must
allow `raise` or catch `XdrError::Invalid(offset, message)`.

```moonbit
let schema = @xdr.parse_schema("struct Item { unsigned int id; string title<32>; };")
let item = @xdr.VStruct([("id", @xdr.VUInt(7U)), ("title", @xdr.VString("hello"))])
let wire = @xdr.encode(schema, "Item", item)
let restored = @xdr.decode(schema, "Item", wire)
assert_true(@xdr.encode(schema, "Item", restored) == wire)
```

The generated `pkg.generated.mbti` is the complete public API. `Reader`/`Writer`
provide scalar codecs; `parse_schema`, `encode`, `decode` provide typed runtime
interchange; `from_json`/`to_json`, `from_hex`/`to_hex` support fixture tools.
`RpcCall`/`RpcReply`, `AuthSys` and `RecordDecoder` compose transport-independent RPC.

## Three executable workflows

```sh
moon run examples/schema --deny-warn
moon run examples/rpc --deny-warn
moon run examples/interchange --deny-warn
```

1. **Protocol/data producers:** parse `.x` declarations, encode a bounded sensor
   record (exact unsigned64, doubles, enum), decode it, assert identical bytes.
2. **Legacy protocol tooling:** encode a procedure argument, attach an AUTH_SYS
   assertion, produce an RPC CALL, fragment into 7-byte pieces, feed bytewise,
   reconstruct and inspect the call, then decode a schema-driven RPC REPLY.
   This is an in-memory wire workflow, not a network service or NFS implementation.
3. **Fixture/interchange authors:** validate JSON containing signed/unsigned64
   extremes, opaque hex and an optional value; write XDR, read it back, output JSON
   without converting 64-bit values through floating point.

All examples assert results and run on all four CI targets.

## Supported declarations and wire rules

- `const`, `typedef`, named/inline `enum`, `struct`, discriminated `union`;
  decimal, C octal and hexadecimal signed32 constants; previously declared constants.
- `int`, `unsigned int`, `hyper`, `unsigned hyper`, `bool`, `float`, `double`,
  bounded ASCII `string`, fixed/variable `opaque`, fixed/variable arrays and pointers.
- Forward type references, recursive pointers/variable arrays; mandatory cycles fail.
- Integer arithmetic preserves all 64 bits; IEEE scalar binary codecs retain special
  values. JSON deliberately rejects non-finite numbers. Padding must be zero;
  boolean/discriminant/enum values and trailing bytes are checked.
- Struct values are **ordered** `(field_name, Value)` arrays in schema order.
  `VUnion(tag, payload)` omits source arm names; `VOptional(None/Some(...))` is explicit.
- Union labels use signed32 constants. For unsigned discriminants the same 32-bit
  pattern is used; positive label literals above INT32_MAX are not accepted.
- Explicit declarations may have larger bounds than the operation budget, but runtime
  budgets still apply. An omitted `< >` bound is `limits.max_items`, not UINT32_MAX.
  `type_names()` uses MoonBit shortlex string order, not alphabetical order.

## JSON convention (project-defined, not an RFC encoding)

| XDR | JSON |
| --- | --- |
| int / uint | checked integral number (integer lexical form when parsed) |
| hyper / unsigned hyper | exact decimal **string** |
| enum | input name or signed32 number; numeric output |
| opaque | even-length hexadecimal string, no whitespace |
| optional | `null` or `{"some": VALUE}`; wrapper preserves nested optionals |
| struct / array | exact-key object / array |
| union | `{"tag": NUMBER, "value": VALUE}` |
| void | `null` |

Parsed integer lexemes with fractions or exponent notation are rejected, including
`1.0` and `1e0`; this avoids silent truncation in the underlying JSON conversion.
Float/double JSON conversion is numeric and does not preserve negative-zero spelling
or NaN payloads. Use binary scalar APIs when bit-level floating representation matters.

## Safety and operational limits

Defaults: 1 MiB input/output/record bytes; 65,536 aggregate value items; depth 64;
65,536 schema tokens. Overrides are validated: max 64 MiB, 1,048,576 items/tokens,
depth 128. Schema finite-value analysis has a work budget of 4 × schema token limit.
It may reject unusually large otherwise valid type graphs. See [SECURITY.md](SECURITY.md).

A `RecordDecoder` accepts arbitrary chunk boundaries and multiple records, including
zero-length fragments. Each feed must fit `max_bytes`; each record has byte and
fragment-count limits; one feed has an output-record count limit. Failed feed/finish
poisons the instance permanently; discard that stream and instance. A failing feed
returns no earlier records from that feed. Framed output includes 4 bytes per fragment
and must fit the writer budget. No sockets or timeouts are provided.

## Verify

Pinned compiler: `v0.10.14+7d59c7ec9` (official development toolchain).

```sh
moon info && moon fmt
moon fmt --check
moon check --deny-warn
moon build --deny-warn
moon test --deny-warn
python scripts/reference_vectors.py --check
python scripts/audit.py
```

CI repeats strict check/build/test and all examples on `wasm-gc`, `wasm`, `js`,
`native` using a clean Ubuntu runner. Windows local checks cover the first three;
native validation is delegated to the actual CI job, not claimed as a local pass.
26 tests include 64 independent Python `struct` vectors (384 scalar fields), exact
RPC and composite vectors, every split of a fragmented stream, hostile lengths,
truncation, overflow and allocation/depth/work limits. The same 64 scalar vectors
were also compared byte-for-byte with CPython 3.12 `xdrlib` (PSF); this is bounded
compatibility evidence, not full RFC certification or a performance benchmark.

## Boundaries

No quadruple precision, C preprocessor/expressions, rpcgen code generation, RPC
`program` declarations, sockets, rpcbind, NFS operations, credentials verification,
RPCSEC_GSS, retransmission, timeouts or authentication policy. No competition
acceptance claim. See [architecture](ARCHITECTURE.md), [references](ATTRIBUTION.md),
[AI disclosure](AI-USE.md), [selection evidence](docs/competition/duplicate-check.md).
