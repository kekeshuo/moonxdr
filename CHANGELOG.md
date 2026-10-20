# Changelog

## 0.2.0 — 2026-10-20

- Add typed binary128/quadruple IO, bit classification, exact binary64 widening,
  schema traversal and lossless 32-hex JSON integration.
- Store constants as BigInt; apply signed32/uint32 checks at typed use sites.
- Preserve positive 4294967295 union cases through parser, runtime and JSON;
  reject signed/unsigned aliases and overflows rather than reinterpreting labels.
- Separate uint32 protocol bounds (including omitted UINT32_MAX) from operation caps.
- Enforce union variable scopes and const-bound provenance; accept FF/VT whitespace,
  reject empty fixed bounds/trailing enum commas/named void/invalid identifiers.
- Check string byte budgets before copying; retain embedded ASCII NUL.
- Add independent 176-word/140-rational binary128 fixtures, RFC section 7 wire test,
  full clause matrix, Chinese README and a fourth cross-target workflow.
- Public API changes: schema bounds UInt; constants BigInt; arm labels and VUnion
  tags Int64. Existing signed32 parse_constant_number remains compatibility-only.
- Target all RFC4506 representation/definition rules; no permanent standard-type
  exclusions. Resource policy, convenience extensions and full RPC scope are separate.

## 0.1.0 — 2026-10-16

- Bounded owned XDR primitive IO, exact64 arithmetic, ASCII strings and strict padding.
- Declaration lexer/parser, named graph validation, recursive schema/value runtime.
- Reversible project-specific JSON, decimal64 and hexadecimal fixture conversion.
- ONC RPCv2 calls/all reply statuses, bounded opaque_auth and AUTH_SYS assertions.
- Incremental record-marker assembly with terminal error state and bounded work.
- Three executable downstream workflows; independent oracle and adversarial tests.
- Explicit unsupported scope and multi-target verification workflow.

