# Standards, references and rights

- RFC 4506, XDR: https://www.rfc-editor.org/rfc/rfc4506
- RFC 5531, ONC RPC version 2, including AUTH_SYS and record marking:
  https://www.rfc-editor.org/rfc/rfc5531
- CPython 3.12 `Lib/xdrlib.py` (PSF license):
  https://github.com/python/cpython/blob/3.12/Lib/xdrlib.py
  Read as a mature implementation reference and used privately as a differential
  oracle for 64 scalar vectors. Reference file SHA-256:
  `983c5e8e3090bdbeb94bf4faf841c1f8c916bcbca423863f6870a142d16a4fb8`.
- davecgh/go-xdr (ISC): https://github.com/davecgh/go-xdr
  README, encoding tests and license inspected as another mature behavioral reference.
- MoonBit core (Apache-2.0): https://github.com/moonbitlang/core
  Runtime dependency supplies JSON, collections and fundamental types.

MoonXDR is original MoonBit implementation code, not a translation or vendored copy
of CPython or go-xdr. Upstream source/tests/license texts are not bundled. Protocol
facts were implemented independently; standards prose was not copied. Deterministic
fixtures were newly calculated with Python stdlib `struct`, seed 45065531.
Their regeneration script is original MIT project code. No claim of upstream
endorsement or compatibility beyond the recorded tests is made.

Version 0.2.0 adds original synthetic binary128 word fixtures using Python integer
network-byte conversion (seed 4506128) and an independent exact rational oracle
using Python float.as_integer_ratio. It does not import a binary128 implementation.
The RFC 4506 section 7 test uses the published factual byte vector and an
independently named equivalent schema; no standards prose or example code is copied.
MoonBit core BigInt and Debug are additional official core dependencies.
