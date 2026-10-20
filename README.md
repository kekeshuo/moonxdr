# MoonXDR

[中文文档](README.zh-CN.md) · [RFC 4506 coverage](docs/rfc4506-coverage.md)

Pure MoonBit schema-driven XDR interchange and transport-independent ONC RPCv2 wire tools.
Module: `kekeshuo/moonxdr@0.2.0` · MIT · only official MoonBit core dependencies.

## Purpose and standard target

Protocol authors compile `.x` declarations and interchange typed values. Legacy
integration tools inspect RPC envelopes and reassemble records. Fixture authors
convert exact integers, binary128, opaque bytes and optional values between a local
JSON convention and XDR. These are reusable APIs, not an NFS-specific reader or a
full RPC client/server.

The project targets **all data types and declaration rules of RFC 4506**, not a
permanent subset. Version 0.2.0 adds typed quadruple precision and correct unsigned
case/bound semantics. The [clause matrix](docs/rfc4506-coverage.md) maps implemented
behavior to tests and separates protocol rules from resource budgets and extensions.
This is tested coverage, **not independent certification or organizer acceptance**.
Any remaining standard discrepancy is a bug to address, not a permanently excluded
standard feature. RFC 5531 support is separately limited to wire envelopes/framing.

## Install and quick start

```sh
moon add kekeshuo/moonxdr@0.2.0
```

Add `"kekeshuo/moonxdr" @xdr` to your package imports. Calling functions must allow
`raise` or catch `XdrError::Invalid(offset, message)`.

```moonbit
let schema = @xdr.parse_schema(
  "typedef quadruple Q; union Measurement switch(unsigned int tag) { case 4294967295: Q reading; default: void; };",
)
let q = @xdr.Quadruple::from_hex("3fff0000000000000000000000000000")
let value = @xdr.VUnion(4294967295L, @xdr.VQuadruple(q))
let wire = @xdr.encode(schema, "Measurement", value)
assert_eq(@xdr.to_hex(wire), "ffffffff3fff0000000000000000000000000000")
assert_true(@xdr.encode(schema, "Measurement", @xdr.decode(schema, "Measurement", wire)) == wire)
```

This exact declaration, expected bytes and JSON round trip run in
`moon run examples/standard --deny-warn`. The generated `pkg.generated.mbti`
is the public API, including `Reader`/`Writer`, `parse_schema`, `encode`/`decode`,
`from_json`/`to_json`, exact decimal64 and hex helpers, RPC and record APIs.

## Supported standard behavior

- `const`, `typedef`, named/inline enums, structs, discriminated unions; decimal,
  octal and hexadecimal constants stored as exact `BigInt`, then range-checked at use.
- All XDR scalar types: int/uint, hyper/uhyper, bool, float, double, **quadruple**.
- ASCII strings (including embedded NUL), fixed/variable opaque, fixed/variable
  arrays, recursive optional data, void union arms and typedef discriminants.
- Enum values and int discriminants are signed32; uint discriminants and length
  bounds cover `0..4294967295`. Unsigned `case -1` is invalid, not an alias of MAX.
- Omitted `<>` has protocol bound `4294967295U`. Declared bounds are independent
  of operation limits; schema acceptance does not promise allocating the maximum.
- Field order, union selection/default, unique names/cases, prior const bounds,
  boolean/enum membership, zero padding and complete input consumption are checked.
- `Quadruple` stores sign/exponent/112 fraction bits in two UInt64 words, preserving
  zero, subnormals, infinity and NaN payloads. `from_double` widens binary64 exactly;
  it never substitutes a Double for a 128-bit value. XDR interchange does not require
  implementing IEEE128 arithmetic or decimal rounding; those are not claimed here.

## Four executable downstream workflows

```sh
moon run examples/schema --deny-warn
moon run examples/rpc --deny-warn
moon run examples/interchange --deny-warn
moon run examples/standard --deny-warn
```

1. Data producers parse sensor declarations, encode/decode exact64 records and
   assert identical bytes.
2. Integration tooling attaches AUTH_SYS to a procedure payload, fragments an RPC
   CALL, reconstructs bytewise and decodes a schema-selected reply. No socket service.
3. Fixture authors exchange exact64 JSON, opaque bytes and explicit optional values.
4. Standard interoperability authors combine binary128 with a literal UINT32_MAX
   union case and verify exact network bytes and JSON round trips.

## Project-defined JSON (not specified by RFC 4506)

| XDR | JSON |
| --- | --- |
| int / uint / enum | checked integral number; enum also accepts a name |
| hyper / uhyper | exact decimal string |
| quadruple | exactly 32 hex digits in network word order; all bits retained |
| float / double | finite JSON number; use binary APIs for NaN/payload/negative-zero fidelity |
| opaque | even-length hex string |
| optional | `null` or `{"some": VALUE}`; nested optionals remain distinguishable |
| struct / array | exact-key object / array |
| union | `{"tag": NUMBER, "value": VALUE}`; signedness follows schema |
| void | `null` |

Integer number lexemes containing a fraction/exponent are rejected, including
`1.0` and `1e0`, to prevent underlying JSON conversion from truncating inputs.
Struct `Value`s are ordered `(field_name, Value)` arrays in declaration order.

## Limits and language extensions

Default operation limits: 1 MiB bytes, 65,536 aggregate items/tokens, depth 64.
Allowed configuration maxima: 64 MiB, 1,048,576 items/tokens, depth 128.
A constant literal has a 4,096-character resource limit; it is not restricted to
signed32 or signed64. Type graph analysis has a work budget of four times the token
limit. These caps can reject standard-valid large inputs; they do not change the
schema's declared sizes or label domains. `type_names()` uses MoonBit shortlex order.

Documented convenience extensions include `//` comments, `0X` and negative hex/octal
literals, prior-constant aliases and forward type references. These do not replace
standard syntax. C preprocessing, expressions, rpcgen service generation and RPC
`program` syntax are not RFC 4506 requirements. Full RPC services, sockets, rpcbind,
NFS, retransmission, credentials verification and RPCSEC_GSS are separate work.
AUTH_SYS is an untrusted assertion, **not authentication**.

Readers own their input copies. Do not mutate public Type/Value arrays during use.
RecordDecoder is a bounded single-stream state machine; errors poison it, and the
caller must discard it and impose transport timeouts. See [SECURITY.md](SECURITY.md).

## Verify and version migration

Pinned official development compiler: `v0.10.14+7d59c7ec9`.

```sh
moon info && moon fmt
moon fmt --check
moon check --deny-warn
moon build --deny-warn
moon test --deny-warn
python scripts/reference_vectors.py --check
python scripts/reference128.py --check
python scripts/audit.py
```

45 tests include 64 independent Python struct vectors (384 scalar fields), 176
binary128 word vectors, 140 exact rational binary64-widening vectors, the RFC
section 7 example bytes, UINT32_MAX union regressions, malformed lengths, recursion
and record-stream boundaries. Fixtures are synthetic; tests/generated data do not
count toward production source size. CI performs checks/build/tests and all four
workflows on wasm-gc, wasm, js and native. Local Windows execution covers the first
three; native execution is checked by the actual Linux CI job.

0.2.0 intentionally changes public schema bounds to UInt, schema constants to
BigInt, and arm labels / VUnion tags to Int64. Use an `L` suffix for explicit tags.
`parse_constant_number` remains a signed32 compatibility helper only; new schema
parsing uses `parse_integer_constant`. Version 0.1.0 is not overwritten.

## License and provenance

Original MIT implementation, not a port. See [ATTRIBUTION.md](ATTRIBUTION.md) for
RFC4506/5531, CPython xdrlib (PSF), go-xdr (ISC) behavior references and core
(Apache-2.0). No upstream implementation/tests are bundled. The independent Python
oracles are original project code. [AI-USE.md](AI-USE.md) discloses AI assistance;
[architecture](ARCHITECTURE.md) and [bounded duplicate review](docs/competition/duplicate-check.md)
describe implementation and ecosystem boundaries. No competition approval claim.
