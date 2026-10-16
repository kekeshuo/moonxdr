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
- https://github.com/shop1111/moon_sourcemap
- https://mooncakes.io/docs/hrwqe/cf_ocean
- https://github.com/hrwqe/cf_ocean
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
'''
