# Topic selection and bounded semantic duplication review

Review date: **2026-10-16**. This is engineering evidence, not an application or a
claim of organizer approval/absolute uniqueness. MoonIsotonic was reported by the
participant as not passed; no organizer rejection reason was supplied. It remains
unchanged; MoonXDR is a different input/task/algorithm family, not a rename.

## Demand and acceptance baseline

RFC 4506 defines interoperable external data representations and a declaration
language. RFC 5531 composes XDR into RPC messages and record-marked byte streams.
CPython xdrlib and go-xdr show mature independent demand for reusable codecs.
MoonBit protocol authors otherwise need to reproduce lengths, padding, unions,
64-bit values and procedure envelopes. A reusable schema interpreter plus wire
toolkit addresses that task without claiming a full network/RPC/NFS service.

Delivered checks: independent scalar vectors, exact composite/RPC fixtures, checked
JSON conversion, all reply alternatives, bytewise fragmented streams, hostile
input/resource limits and three executable consumer workflows. See README.

## Candidate domains, evidence and decisions

Searches used `moon search TERM --limit 100 --json`, official MoonCakes metadata,
public GitHub API search (first 100 results with total counts), official awesome
list and a shared permanent registry. Public source was inspected for adjacent
packages, not just titles. Research logs are private to avoid publishing account
operation context. Package/repo links below allow independent review.

| Domain/candidate | Existing evidence and actual inspection | Classification / decision |
| --- | --- | --- |
| Avro schema binary/resolution | `yugonlian/moon-avro@0.3.0`: MoonCakes metadata/README, GitHub tree, actual `codec/binary.mbt` and codec tests | Direct established overlap; reject rather than repackage a second codec |
| Terminal emulator/state machine | `tonyfettes/libghostty-vt`, `tonyfettes/vte`, `fundon/vtty@0.1.0`: metadata/README/trees; vtty metadata links upstream Rust `pindash-io/vtty`, not a proven MoonBit screen implementation | Existing parser/binding approaches, insufficient grounded independent gap; reject. Do not infer pure MoonBit emulator parity from Rust source |
| Source-map tooling | `shop1111/moon_sourcemap@0.1.1` and Derk2006/xiaoxiao: metadata/README/tree and actual `mappings_decode.mbt`, matching tests | Direct decoder/format overlap; reject |
| XDR schema/runtime and RPC wire | No direct hits in recorded XDR/ONC RPC MoonCakes or MoonBit-specific GitHub searches; adjacent `hrwqe/cf_ocean@0.1.4` actual binary reader, tests and generated interface inspected | Selected subject to bounded review below |

Sources inspected / catalogued:
- https://mooncakes.io/docs/yugonlian/moon-avro
- https://github.com/yugonlian/moon-avro
- https://github.com/tonyfettes/libghostty-vt
- https://github.com/tonyfettes/vte
- https://mooncakes.io/docs/fundon/vtty
- https://github.com/pindash-io/vtty
- https://mooncakes.io/docs/shop1111/moon_sourcemap
- https://github.com/shop1111/moon-sourcemap
- https://mooncakes.io/docs/hrwqe/cf_ocean
- https://github.com/hrwqe/moonbit-cf-ocean
- https://github.com/moonbitlang/awesome-moonbit
- https://www.rfc-editor.org/rfc/rfc4506
- https://www.rfc-editor.org/rfc/rfc5531
- https://github.com/python/cpython/blob/3.12/Lib/xdrlib.py
- https://github.com/davecgh/go-xdr

The permanent registry also contained MoonWire (framing-focused, rejected), MoonIon,
moonfbs and MoonTSInspect. Their full recorded fingerprints were compared. Framing
alone would repeat the narrow rejected task; MoonXDR's principal work is declaration
parsing, graph validation and recursive typed XDR interchange, not a framing rename.
An exclusive registry lock was used to reserve MoonXDR before implementation while
preserving other entries and recording external candidates.

## Semantic comparison matrix

| Axis | MoonXDR | cf_ocean | Generic MoonWire framing |
| --- | --- | --- | --- |
| Users | protocol authors, legacy integration tooling, fixture/interchange authors | scientific dataset/CF consumers | transport/packet consumers |
| Task | compile `.x`, validate typed values, interoperable XDR and RPC envelope analysis | read NetCDF classic/CDF2 and scientific metadata/numeric data | frame byte payloads |
| Inputs | declaration text, recursive Value/JSON, RPC record stream | NetCDF file/dataset bytes | opaque byte messages |
| Core behavior | grammar/constants/types, finite graph check, unions/arrays/optionals, exact64, JSON, RPC status machine | dataset headers, dimensions/variables/attributes and CF domain access | marker/length processing |
| Outputs | reusable schema graph, typed values, exact binary, JSON, RPC call/reply structures | scientific data model | byte frames |
| Interface | parse_schema / encode / decode / JSON / RPC / bounded incremental decoder | dataset binary reader + dataset API | framing API |
| Scope relationship | standards-generic original library | shared primitive big-endian/XDR ancestry, different core task | small supporting subcomponent only |

Reusing or extending a NetCDF dataset engine would invert its domain model and
still require a new declaration/runtime/RPC subsystem. No upstream code is copied.
This supports independent construction, not a claim that collaboration is impossible.

## Search coverage and limits

Terms included Avro/fastavro/schema resolution/serialization; terminal emulator/
VT100/ECMA-48; sourcemap/source map/VLQ; XDR/external data representation/NetCDF/
rpcgen/sunrpc/ONC RPC/RFC4506/RFC5531, plus exploratory domains (pcapng, iCalendar,
GeoTIFF, BSON, MessagePack, Reed Solomon, MIDI, Datalog). GitHub MoonBit-specific
queries included `xdr language:MoonBit`, `onc rpc moonbit`, `rpcgen moonbit`,
`RFC5531 moonbit`, `xdr codec moonbit` (recorded total 0); broader RFC4506 results
were mature other-language implementations. Broad external-data-representation
searches also return irrelevant packages, not only zero hits.

Search indexing, result windows and descriptions can miss unpublished, private,
newly published or differently named work. vtty's Rust upstream is not evidence of
MoonBit core implementation scope. The review establishes only that **no mature
direct replacement was found in the recorded, source-reviewed scope**. It cannot
prove universal absence or guarantee competition acceptance. Release-time reverse
search must repeat core behavior terms before publication.

## Automatic decision scores (1–5, judgment not measurement)

| Candidate | breadth | user diversity | reuse | overlap safety | depth | validation | delivery | maintenance | total | hard gate |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Avro | 5 | 4 | 5 | 1 | 5 | 5 | 3 | 3 | 31 | fail direct overlap |
| Terminal | 4 | 4 | 4 | 2 | 5 | 4 | 2 | 2 | 27 | fail grounded gap |
| Source map | 4 | 4 | 5 | 1 | 4 | 5 | 4 | 4 | 31 | fail direct overlap |
| XDR + RPC wire | 4 | 4 | 5 | 4 | 5 | 5 | 4 | 4 | 35 | pass bounded review |

High totals do not override hard failures. Selected MoonXDR has independently
useful parser/runtime/JSON/IO/envelope/stream components, with no full-RPC claim.

## Release-time reverse recheck

Repeated on 2026-10-16 after implementation: MoonCakes `xdr`, `rpcgen`, `rfc5531`
returned successful empty result arrays (limit 100). GitHub repository searches
`xdr language:MoonBit`, `"ONC RPC" moonbit`, `"XDR schema" moonbit` each reported
0 total results (first-100 window). This recheck supplements, not replaces, the
source-level adjacent-project review above. It has the same indexing limitations.

## RFC4506 repair reverse recheck — 2026-10-20

This is a repair of the existing MoonXDR, not a new topic. The earlier delivery
excluded quadruple and used signed32 constants; those were real limitations, not
properties of RFC4506. Version 0.2.0 removes those restrictions and targets every
RFC4506 representation/declaration category. See the clause-to-test matrix in
[the coverage document](../rfc4506-coverage.md). Resource budgets, convenience
syntax extensions and the distinction between exchange and arithmetic remain
explicit. This record does not certify strict grammar membership or acceptance.

Repeated MoonCakes CLI searches, limit 50 per term: `xdr`, `rfc4506`, `onc rpc`,
`XDR schema` found the existing `kekeshuo/moonxdr@0.1.0`; `rpcgen` and `sunrpc`
returned no modules; `netcdf` found `hrwqe/cf_ocean@0.1.4`. Expanded `external data
representation`, `serialization`, `quadruple`, `binary128` searches were reviewed;
serialization hit the 50-result cap, not an exhaustive registry scan. In
particular **Luna-Flow/floating@0.10.0 already provides binary128**. We do not claim
MoonBit's first binary128 representation, arithmetic or hexadecimal interchange.

GitHub repository queries: `xdr language:MoonBit` and `"ONC RPC" moonbit` each
returned our one repository, `"RFC4506" moonbit` and `"quadruple"
language:MoonBit` returned zero. Code search `"xdr" language:MoonBit` reported
105 results (first-page inspection includes OOXML drawing namespace uses in
moonbitlang/office.mbt, not XDR codec evidence); `"RFC4506" language:MoonBit` and
`"rpcgen" language:MoonBit` returned zero. The official awesome-moonbit list was
read at 0bb1697fb50405cceccbca3d72a1e92dc45f1ebe, without an XDR entry. Code indexing,
result windows, broad-query caps and unindexed/private projects limit conclusions.
The shared registry's MoonXDR, MoonWire, MoonIon, moonfbs and related fingerprints
were revisited; extending this existing XDR implementation is preferable to a
second renamed codec or framing-only project. Historical records are preserved.

### Source-reviewed adjacent projects

| Project / maintained scope | Users, inputs and actual behavior | Relationship / decision |
| --- | --- | --- |
| [Luna-Flow/floating](https://github.com/Luna-Flow/floating), MoonCakes 0.10.0, Apache-2.0 | Numerical users; BinFloat/BinCoeff, contexts/rounding/flags, binary16/32/64/128 formats. `BinaryInterchange::from_hex`, `from_bits`, `to_hex`, `to_bin_float` explicitly implement binary128 fields and NaN payloads; IEEE tests exercise interchange and arithmetic. | Same-direction component overlap in raw IEEE128 exchange, **not a generic XDR schema/RPC implementation**. MoonXDR's two-word Quadruple is a codec value integrated with `.x` declarations, unions, nested values and 16-byte network IO, not a competing arithmetic library. Hex can be an integration boundary; no floating dependency, port or copied source is included. Rebuilding numerical arithmetic would fail the scope gate. |
| [hrwqe/moonbit-cf-ocean](https://github.com/hrwqe/moonbit-cf-ocean), MoonCakes cf_ocean 0.1.4, Apache-2.0, last pushed 2026-08-24 | Ocean/NetCDF readers; CDF1/2 magic, dimensions/attributes/variables and ByteBuffer numeric reads; actual binary reader, interface and tests reviewed again. | Adjacent XDR-derived file format, not `.x` declaration parsing, typed discriminated unions, arbitrary schema-driven values or RPC envelopes. General codec requirements cannot be met by its current dataset API without changing its main task. |

Floating evidence: README blob `37ec161ae13a28372a39e70c8fca2866414fa08f`,
bin_float README `69d437347cfea123ee78a4b0db6897e86d518c64`, interface
`4518e3a5a476da6dc9b22346afdf4d4401f4b36e`, **actual interchange implementation**
`40d2030fa37001f729e7d4fe3e7b87c17c9e564f`, IEEE tests
`613ab6a4c6a73c99c6adab729381df443437abac`. Registry manifest 0.10.0 reported
successful build and checksum
`814c1ec1f2bdb5442fc70d588360c308ae480f441fa7c0e39994c8792e7aae56`.
The GitHub source snapshot is distinguished from the registry version rather
than assumed byte-identical. cf_ocean reader blob
`ac1fc4507897442ac69134a27bcfec4fdd4b1035`, tests
`43b5f42ec57c9cf4c45917f762796d0f307280df`, interface
`f679c744012d788ef7f5bf9e1ccfdb65a7cb9071`.

**Decision:** in this bounded, source-reviewed scope no mature direct replacement
for the combined generic XDR declaration/runtime workflow was found. Repair the
existing implementation rather than start another project. This conclusion does
not deny component overlaps, prove universal uniqueness or guarantee contest
approval. Raw operation evidence stays outside the public project.
