# Architecture

`lexer` → `parser` + `compound` → `Schema::validate` creates a named graph of
algebraic `Type` nodes. The lexer retains source character offsets; constant
parsing is checked signed32 arithmetic. Compound duplicate sets use maps.
A bounded fixed-point computes whether each named graph node has any finite value;
mandatory cycles fail, while optional/variable-array recursion can terminate.
Typedef resolution and inline/recursive traversal have explicit depth bounds.

`bounds`, `scalars`, `opaque` implement owned, network-order binary IO. Readers copy
input, writers return copies; length checks happen before allocation. Padding is
written as zero and checked on input. XDR strings are ASCII, not UTF-8 blobs.
`marshal`/`unmarshal` walk Type + Value, carrying one shared aggregate/depth budget.
The decoder consumes the entire supplied value; RPC payload bytes are separately
interpreted against an application-selected procedure schema.

`decimal`, `json_input`, `json_output` implement a lossless integer/optional JSON
convention. Decimal64 parsing uses overflow checks and never a Double intermediate.
JSON input is validated through the same encoder, not a weaker parallel type system.

`rpc_call`, `rpc_reply`, `auth_sys` implement the RFC 5531 message envelopes,
opaque_auth and AUTH_SYS assertion layout only. Unknown authentication flavors are
opaque bytes; auth failure numeric codes are preserved. Version ranges are checked.
Successful procedure results are external aligned XDR bytes; non-success replies
must consume all bytes with no additional payload.

`record_encode` adds record markers. `record_decode` keeps a four-byte accumulator,
remaining body length, last-fragment bit, bounded fragment counter and owned current
record. It appends each input body byte once rather than repeatedly concatenating
prefixes. Completed buffers are copied out. Feed failure drops partial state and
poisons the decoder, so partially validated transport state cannot be reused.
Memory is bounded by operation byte/item limits, including feed size/output count;
there is no transport flow control or scheduling in this library.

Tests are not included in production LOC. The reference vector file is generated
test data only. Examples are external package consumers, also excluded from LOC.
