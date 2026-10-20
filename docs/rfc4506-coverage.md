# RFC 4506 implementation and validation matrix — 0.2.0

Target: the complete set of data representations and declaration rules in RFC 4506
(May 2006), rather than a permanently frozen subset. This is an implementation/test
map, not a standards-body certificate, exhaustive proof, or competition decision.
Unknown discrepancies are defects to fix. Read this alongside the generated API,
source and reproducible tests, not as a replacement for them.

## Clause-level map

| RFC clause | Implemented behavior | Principal code | Executable evidence |
| --- | --- | --- | --- |
| 3, 4 | Four-byte network representation and zero padding | bounds, scalars, opaque | primitives_wbtest; reference_wbtest |
| 4.1–4.2 | Full signed/unsigned32 domains | scalars | primitive extremes; 64 independent struct vectors |
| 4.3 | Distinct signed32 enumerators, declared membership | compound, validate, marshal/unmarshal | schema_wbtest; conformance_wbtest |
| 4.4 | Boolean exactly zero/one | scalars | primitives; optional/union equivalence and invalid tag tests |
| 4.5 | Full signed/unsigned64 without Double intermediate | scalars, decimal | reference_wbtest; json_wbtest |
| 4.6–4.7 | IEEE binary32/binary64 network bits | scalars | scalar reference and signed-zero/NaN payload tests |
| 4.8 | Typed binary128, 1 sign/15 exponent/112 fraction bits, 16 network bytes | quadruple; schema; parser; marshal/unmarshal | quadruple_wbtest; reference128_wbtest; examples/standard |
| 4.9–4.10 | Fixed/variable opaque and padding; uint32 declaration bounds | opaque; parser | primitives; conformance max-bound and hostile-length tests |
| 4.11 | ASCII strings including embedded NUL, length and padding | opaque | embedded-NUL conformance test; malformed padding tests |
| 4.12–4.13 | Fixed/variable arrays; omitted bound is UINT32_MAX | parser; marshal/unmarshal | conformance unsigned bounds and independent-budget tests |
| 4.14 | Ordered structs, distinct member names and typed fields | compound; marshal/unmarshal | schema/runtime/json tests; RFC section 7 bytes |
| 4.15 | int/uint/bool/enum or alias discriminants, legal distinct cases, default | compound; validate; marshal/unmarshal | literal 4294967295 case; signed/unsigned range rejection; default and typedef tests |
| 4.16 | Zero-byte void arms and anonymous declarations | compound; marshal/unmarshal | standalone struct/typedef void regression; unsigned max void union; optional/boolean union equivalence |
| 4.17 | Exact decimal/octal/hex constants, contextual range checks | constants; parser | beyond-128-bit positive/negative constants; malformed syntax and typed overflow tests |
| 4.18 | Type aliases and typedef discriminants | parser; schema.resolve | schema_wbtest; conformance unsigned alias tests |
| 4.19 | Optional data and terminating recursive pointers | parser; graph validation; recursive runtime | schema/runtime/limits tests; optional union equivalence |
| 4.20 | Discussion of possible future language extensions, not additional current types | no new normative codec feature | not represented as an unimplemented required type |
| 5 | Representation rationale | network-order implementation | binary expected-byte comparisons |
| 6.2–6.3 | Comments, whitespace, identifiers, literals and declarations | lexer; parser; compound | schema tests; FF/VT whitespace; lexical error tests |
| 6.4(1) | Reserved keywords not usable as identifiers | parser.identifier | malformed declaration tests |
| 6.4(2) | Array sizes are uint32; identifier comes from prior const definition | parser.bound; Schema.constant_defs | const provenance and 4294967296 rejection tests |
| 6.4(3–4) | Distinct symbols and struct/union variable scopes | parser; compound | duplicate symbols/members, union discriminant collision, nested scope tests |
| 6.4(5) | Discriminants resolve to legal integer types and labels match their domain | validate_tag | enum/bool failures, uint -1 rejection, uint MAX success |
| 7 | Published illustrative binary record | independently named equivalent test schema | 48 exact expected bytes from RFC, not output-derived snapshots |
| 8 | Pre-allocation size checks, work/depth caps, embedded NUL preservation | bounds; opaque; runtime; record decoder | limits and hostile-input tests; SECURITY.md |
| 9–10, 12–13 | IANA, security/reference/editorial material | attribution/documentation, not codec methods | ATTRIBUTION.md |
| 11 | Zero/subnormal/infinity/quiet and signaling NaN categories | Quadruple.classify and word-preserving IO | class vectors; raw-bit corpus and exact widening corpus |

## Required boundary demonstrations

Run `moon run examples/standard --deny-warn` on any supported target. The declaration
is accepted literally, without rewriting the unsigned label as -1:

```xdr
typedef quadruple Q;
union Measurement switch (unsigned int tag) {
  case 4294967295: Q reading;
  default: void;
};
```

With binary128 1.0 (`3fff0000000000000000000000000000`) the exact complete wire is
`ffffffff3fff0000000000000000000000000000`. The example checks bytes, typed decoding
and JSON re-encoding. Tests additionally exercise signed zero, least and greatest
subnormal, least normal, greatest finite value, infinities and both NaN classes.
NaN payload bits are retained, not canonicalized by a host floating conversion.

UInt labels are mathematical integers, not signed bit-pattern aliases. `-1` and
`4294967296` are rejected for uint. Signed int labels reject `4294967295`.
Enum remains signed32. Constants may be wider than 64/128 bits; only their typed
use imposes enum/case/bound ranges. Positive UINT32_MAX is tested in decimal,
octal, hex and named-const forms, including a typedef discriminant.

## Numerical representation versus arithmetic

Quadruple is a dedicated value type with sign/exponent/fraction/class APIs,
lossless read/write, exact binary64 widening and schema/JSON integration. It is
not merely an unknown type silently treated as opaque, and never falls back to
Double. IEEE128 arithmetic and decimal-to-binary rounding are not specified by the
XDR exchange format and are not advertised. This distinction is not an exclusion
of the RFC quadruple representation. Every 128-bit word can be represented and
exchanged, including non-finite payloads and values outside binary64 range.

## Standard semantics versus operation policy

- `<>` and explicit `<4294967295>` have the same declared protocol bound, UInt MAX.
- The schema can retain `[4294967295]` without attempting to allocate it.
- A smaller caller budget rejects an operation as a resource limit; it does not
  replace that schema bound or make the declaration standard-invalid.
- Defaults are 1 MiB bytes, 65,536 items/tokens and depth 64. Configurable maxima
  are 64 MiB, 1,048,576 items/tokens and depth 128. Single constant text is capped
  at 4,096 characters; graph work is capped at four times the token limit.
- Tests cannot exhaust 2^128 values or all declarations. The 176 raw word vectors
  and 140 independent rational widening vectors are bounded evidence, not proof.

Convenience extensions: `//`, uppercase `0X`, negative hex/octal, const aliases and
forward type references. Some permissive constructs (such as default-only unions)
are accepted in addition to the RFC grammar; acceptance is not a strict-language
membership validator. The canonical RFC syntax remains supported. Constant
expressions/C preprocessing/rpcgen `program` and generated service stubs are outside
RFC 4506. RFC 5531 envelope/framing support is explicitly separate from full RPC,
NFS, networking and authentication, so those exclusions do not narrow the RFC4506
representation target. JSON is a project-defined lossless interchange convention.

## Reproduction

`moon test --deny-warn` exercises the matrix; `python scripts/reference_vectors.py
--check` and `python scripts/reference128.py --check` reproduce independent fixtures.
Four-target CI also builds and runs the standard example. No organizer approval,
external certification or unrestricted resource promise follows from a green run.
